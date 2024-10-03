//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import BigInt
import web3

public enum SmartAccountProviderError: Error {
    case notConnected(String)
    case noRpc(String)
    case noParameters(String)
    case noTransaction(String)
}

open class SmartAccountProvider: ISmartAccountProvider {
    public let rpcClient: Erc4337Client!
    public let chain: Chain!
    
    private let entryPointAddress: EthereumAddress!
    private let opts: SmartAccountProviderOpts!

    private var account: ISmartContractAccount?
    private var gasEstimator: ClientMiddlewareFn!
    private var feeDataGetter: ClientMiddlewareFn!
    private var paymasterDataMiddleware: ClientMiddlewareFn!
    private var overridePaymasterDataMiddleware: ClientMiddlewareFn!
    private var dummyPaymasterDataMiddleware: ClientMiddlewareFn!

    @Published public var isConnected = false

    public init(client: Erc4337Client?, rpcUrl: String?, entryPointAddress: EthereumAddress?, chain: Chain, opts: SmartAccountProviderOpts? = nil) throws {
        var rpcClient = client
        
        if rpcClient == nil && rpcUrl != nil {
            rpcClient = createPublicErc4337Client(rpcUrl: rpcUrl!, chain: chain)
        }

        guard let rpcClient = rpcClient else {
            throw SmartAccountProviderError.noRpc("No rpcUrl or client provided")
        }

        self.rpcClient = rpcClient
        self.chain = chain
        self.entryPointAddress = entryPointAddress
        self.opts = opts
        
        self.gasEstimator = defaultGasEstimator
        self.feeDataGetter = defaultFeeDataGetter
        self.paymasterDataMiddleware = defaultPaymasterDataMiddleware
        self.dummyPaymasterDataMiddleware = defaultDummyPaymasterDataMiddleware
        self.overridePaymasterDataMiddleware = defaultOverridePaymasterDataMiddleware
    }
    
    public func connect(account: ISmartContractAccount) {
        self.account = account
        self.isConnected = true
    }
    
    public func disconnect() {
        self.account = nil
        self.isConnected = false
    }
    
    public func getAddress() async throws -> EthereumAddress {
        guard var account = self.account else {
            throw SmartAccountProviderError.notConnected("Account not connected")
        }
        
        return try await account.getAddress()
    }
    
    public func sendUserOperation(
        data: UserOperationCallData,
        overrides: UserOperationOverrides? = nil
    ) async throws -> SendUserOperationResult {
        guard self.account != nil else {
            throw SmartAccountProviderError.notConnected("Account not connected")
        }

        let uoStruct = try await self.buildUserOperation(data: data, overrides: overrides)
        return try await sendUserOperation(uoStruct: uoStruct)
    }
    
    public func sendUserOperation(data: [UserOperationCallData], overrides: UserOperationOverrides?) async throws -> SendUserOperationResult {
        guard self.account != nil else {
            throw SmartAccountProviderError.notConnected("Account not connected")
        }

        let uoStruct = try await self.buildUserOperation(data: data, overrides: overrides)
        return try await sendUserOperation(uoStruct: uoStruct)
    }
    
    public func buildUserOperation(
        data: UserOperationCallData,
        overrides: UserOperationOverrides? = nil
    ) async throws -> UserOperationStruct {
        guard var account = self.account else {
            throw SmartAccountProviderError.notConnected("Account not connected")
        }

        let initCode = try await account.getInitCode()
        let address = try await self.getAddress()
        let nonce = try await account.getNonce()
        let callData = await account.encodeExecute(target: data.target, value: data.value ?? BigUInt(0), data: data.data)
        let signature = account.getDummySignature()

        var userOperationStruct = UserOperationStruct(
            sender: address.asString(),
            nonce: nonce,
            initCode: initCode,
            callData: callData,
            paymasterAndData: "0x",
            signature: signature
        )

        return try await self.runMiddlewareStack(uoStruct: &userOperationStruct, overrides: overrides ?? UserOperationOverrides())
    }
    
    public func buildUserOperation(
        data: [UserOperationCallData],
        overrides: UserOperationOverrides? = nil
    ) async throws -> UserOperationStruct {
        guard var account = self.account else {
            throw SmartAccountProviderError.notConnected("Account not connected")
        }

        let initCode = try await account.getInitCode()
        let address = try await self.getAddress()
        let nonce = try await account.getNonce()
        let callData = await account.encodeBatchExecute(txs: data)
        let signature = account.getDummySignature()

        var userOperationStruct = UserOperationStruct(
            sender: address.asString(),
            nonce: nonce,
            initCode: initCode,
            callData: callData,
            paymasterAndData: "0x",
            signature: signature
        )

        return try await self.runMiddlewareStack(uoStruct: &userOperationStruct, overrides: overrides ?? UserOperationOverrides())
    }
    
    public func dropAndReplaceUserOperation(
        uoToDrop: UserOperationRequest,
        overrides: UserOperationOverrides? = nil
    ) async throws -> SendUserOperationResult {
        var uoToSubmit = UserOperationStruct(
            sender: uoToDrop.sender,
            nonce: BigUInt(hex: uoToDrop.nonce)!,
            initCode: uoToDrop.initCode,
            callData: uoToDrop.callData,
            paymasterAndData: uoToDrop.paymasterAndData,
            signature: Data(hex: uoToDrop.signature)!
        )
        
        // Run once to get the fee estimates
        // This can happen at any part of the middleware stack, so we want to run it all
        let estimates = try await self.runMiddlewareStack(uoStruct: &uoToSubmit, overrides: overrides ?? UserOperationOverrides())
        
        let newOverrides = UserOperationOverrides(
            maxFeePerGas: max(
                estimates.maxFeePerGas ?? BigUInt(0),
                bigIntPercent(
                    base: BigUInt(hex: uoToDrop.maxFeePerGas)!,
                    percent: BigUInt(110)
                )
            ),
            maxPriorityFeePerGas: max(
                estimates.maxPriorityFeePerGas ?? BigUInt(0),
                bigIntPercent(
                    base: BigUInt(hex: uoToDrop.maxPriorityFeePerGas)!,
                    percent: BigUInt(110)
                )
            )
        )

        let uoToSend = try await self.runMiddlewareStack(uoStruct: &uoToSubmit, overrides: newOverrides)
        return try await self.sendUserOperation(uoStruct: uoToSend)
    }
    
    public func waitForUserOperationTransaction(hash: String) async throws -> UserOperationReceipt {
        let txMaxRetries = opts?.txMaxRetries ?? 5
        let txRetryIntervalMs = opts?.txRetryIntervalMs ?? 2000
        let txRetryMultiplier = opts?.txRetryMultiplier ?? 1.5

        for i in 0..<txMaxRetries {
            let txRetryIntervalWithJitterMs = Double(txRetryIntervalMs) * pow(txRetryMultiplier, Double(i)) + Double.random(in: 0..<100)
            try await Task.sleep(nanoseconds: UInt64(txRetryIntervalWithJitterMs) * 1_000_000)

            do {
                return try await rpcClient.getUserOperationReceipt(hash: hash)
            } catch {
                if i == txMaxRetries - 1 {
                    throw error
                }
            }
        }

        throw SmartAccountProviderError.noTransaction("Failed to find transaction for User Operation")
    }
    
    @discardableResult
    public func withFeeDataGetter(feeDataGetter: @escaping ClientMiddlewareFn) -> ISmartAccountProvider {
        self.feeDataGetter = feeDataGetter
        return self
    }
    
    @discardableResult
    public func withGasEstimator(gasEstimator: @escaping ClientMiddlewareFn) -> ISmartAccountProvider {
        self.gasEstimator = gasEstimator
        return self
    }
    
    @discardableResult
    public func withPaymasterMiddleware(dummyPaymasterDataMiddleware: ClientMiddlewareFn?, paymasterDataMiddleware: ClientMiddlewareFn?) -> ISmartAccountProvider {
        
        if let dummyPaymasterDataMiddleware = dummyPaymasterDataMiddleware {
            self.dummyPaymasterDataMiddleware = dummyPaymasterDataMiddleware
        }
        
        if let paymasterDataMiddleware = paymasterDataMiddleware {
            self.paymasterDataMiddleware = paymasterDataMiddleware
        }
        
        return self
    }
    
    private func runMiddlewareStack(
        uoStruct: inout UserOperationStruct,
        overrides: UserOperationOverrides
    ) async throws -> UserOperationStruct {
        let paymasterData = if overrides.paymasterAndData != nil {
            overridePaymasterDataMiddleware
        } else {
            paymasterDataMiddleware
        }
        
        // Reversed order - dummyPaymasterDataMiddleware is called first
        let asyncPipe = chain(paymasterData!, with:
                        chain(gasEstimator, with:
                        chain(feeDataGetter, with:
                              dummyPaymasterDataMiddleware)))
        return try await asyncPipe(rpcClient, &uoStruct, overrides)
    }

    // These are dependent on the specific paymaster being used
    // You should implement your own middleware to override these
    // or extend this class and provider your own implementation
    
    open func defaultDummyPaymasterDataMiddleware(
        client: Erc4337Client,
        operation: inout UserOperationStruct,
        overrides: UserOperationOverrides
    ) async throws -> UserOperationStruct {
        operation.paymasterAndData = "0x"
        return operation
    }
    
    open func defaultOverridePaymasterDataMiddleware(
        client: Erc4337Client,
        operation: inout UserOperationStruct,
        overrides: UserOperationOverrides
    ) async throws -> UserOperationStruct {
        operation.paymasterAndData = overrides.paymasterAndData ?? "0x"
        return operation
    }
    
    open func defaultPaymasterDataMiddleware(
        client: Erc4337Client,
        operation: inout UserOperationStruct,
        overrides: UserOperationOverrides
    ) async throws -> UserOperationStruct {
        operation.paymasterAndData = "0x"
        return operation
    }
    
    open func defaultFeeDataGetter(
        client: Erc4337Client,
        operation: inout UserOperationStruct,
        overrides: UserOperationOverrides
    ) async throws -> UserOperationStruct {
        // maxFeePerGas must be at least the sum of maxPriorityFeePerGas and baseFee
        // so we need to accommodate for the fee option applied maxPriorityFeePerGas for the maxFeePerGas
        //
        // Note that if maxFeePerGas is not at least the sum of maxPriorityFeePerGas and required baseFee
        // after applying the fee options, then the transaction will fail
        //
        // Refer to https://docs.alchemy.com/docs/maxpriorityfeepergas-vs-maxfeepergas
        // for more information about maxFeePerGas and maxPriorityFeePerGas
        
        let feeData = try await rpcClient.estimateFeesPerGas(chain: chain)
        var maxPriorityFeePerGas = overrides.maxPriorityFeePerGas
        
        if maxPriorityFeePerGas == nil {
            maxPriorityFeePerGas = try await rpcClient.maxPriorityFeePerGas()
        }
        
        let maxFeePerGas = overrides.maxFeePerGas ?? (feeData.maxFeePerGas - feeData.maxPriorityFeePerGas + maxPriorityFeePerGas!)

        operation.maxFeePerGas = maxFeePerGas
        operation.maxPriorityFeePerGas = maxPriorityFeePerGas

        return operation
    }
    
    open func defaultGasEstimator(
        client: Erc4337Client,
        operation: inout UserOperationStruct,
        overrides: UserOperationOverrides
    ) async throws -> UserOperationStruct {
        var estimates: EstimateUserOperationGasResponse? = nil

        if (overrides.callGasLimit == nil ||
            overrides.verificationGasLimit == nil ||
            overrides.preVerificationGas == nil
        ) {
            let request = operation.toUserOperationRequest()
            estimates = try await rpcClient.estimateUserOperationGas(request: request, entryPoint: getEntryPointAddress().asString())
        }

        operation.preVerificationGas = overrides.preVerificationGas ?? estimates!.preVerificationGas
        operation.verificationGasLimit = overrides.verificationGasLimit ?? estimates!.verificationGasLimit
        operation.callGasLimit = overrides.callGasLimit ?? estimates!.callGasLimit
        
        return operation
    }

    // Note that the connected account's entryPointAddress always takes the precedence
    public func getEntryPointAddress() throws -> EthereumAddress {
        if let entryPointAddress = self.entryPointAddress {
            return entryPointAddress
        }

        if let accountEntryPointAddress = try self.account?.getEntryPointAddress() {
            return accountEntryPointAddress
        }

        return try chain.getDefaultEntryPointAddress()
    }

    private func sendUserOperation(uoStruct: UserOperationStruct) async throws -> SendUserOperationResult {
        guard let account = self.account else {
            throw SmartAccountProviderError.notConnected("Account not connected")
        }

        guard uoStruct.isValidRequest else {
            throw SmartAccountProviderError.noParameters("Request is missing parameters. All properties on UserOperationStruct must be set. struct: \(uoStruct)")
        }

        let address = try self.getEntryPointAddress()
        let userOperationHash = getUserOperationHash(request: uoStruct, entryPointAddress: address, chainId: self.chain.id)
        var uoStructFinal = uoStruct
        uoStructFinal.signature = try await account.signMessage(msg: userOperationHash)

        let request = uoStructFinal.toUserOperationRequest()
        let uoHash = try await rpcClient!.sendUserOperation(request: request, entryPoint: address.asString())
        
        return SendUserOperationResult(hash: uoHash, request: request)
    }
    
    private func chain<A, B, C>(_ f: @escaping (A, inout B, C) async throws -> B, with g: @escaping (A, inout B, C) async throws -> B) -> ((A, inout B, C) async throws -> B) {
        return { x, y, z in
            return try await f(x, &y, z)
        }
    }
}
