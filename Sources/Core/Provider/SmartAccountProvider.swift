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
    public let rpcClient: BundlerClient!
    public let chain: Chain!
    
    private var middlewareClient: BundlerClient? = nil
    private let opts: SmartAccountProviderOpts!

    private(set) var account: ISmartContractAccount?
    private var gasEstimator: ClientMiddlewareFn!
    private var feeDataGetter: ClientMiddlewareFn!
    private var paymasterDataMiddleware: ClientMiddlewareFn!
    private var overridePaymasterDataMiddleware: ClientMiddlewareFn!
    private var dummyPaymasterDataMiddleware: ClientMiddlewareFn!
    private var userOperationSigner: ClientMiddlewareFn!

    @Published public var isConnected = false

    public init(client: BundlerClient?, rpcUrl: String?, chain: Chain, opts: SmartAccountProviderOpts? = nil) throws {
        var rpcClient = client
        
        if rpcClient == nil && rpcUrl != nil {
            rpcClient = try createPublicBundlerClient(rpcUrl: rpcUrl!, chain: chain)
        }

        guard let rpcClient = rpcClient else {
            throw SmartAccountProviderError.noRpc("No rpcUrl or client provided")
        }

        self.rpcClient = rpcClient
        self.chain = chain
        self.opts = opts
        
        self.gasEstimator = defaultGasEstimator
        self.feeDataGetter = defaultFeeDataGetter
        self.paymasterDataMiddleware = defaultPaymasterDataMiddleware
        self.dummyPaymasterDataMiddleware = defaultDummyPaymasterDataMiddleware
        self.overridePaymasterDataMiddleware = defaultOverridePaymasterDataMiddleware
        self.userOperationSigner = defaultUserOpSigner
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
        
        let entryPoint = try getEntryPoint()
        let initialPaymasterAndData: String? = (entryPoint.version == "0.6.0") ? "0x" : nil

        var userOperationStruct = UserOperationStruct(
            sender: address.asString(),
            nonce: nonce,
            initCode: initCode,
            callData: callData,
            signature: signature,
            paymasterAndData: initialPaymasterAndData
        )
        
        
        if entryPoint.version == "0.7.0" {
            if try await !account.isAccountDeployed() {
                userOperationStruct.factory = await account.getFactoryAddress()?.asString()
                userOperationStruct.factoryData = try await account.getFactoryData(initCode: userOperationStruct.initCode)
            }
        }

        let result = try await self.runMiddlewareStack(uoStruct: userOperationStruct, overrides: overrides ?? UserOperationOverrides())
        
        return result
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
        
        let entryPoint = try getEntryPoint()
        let initialPaymasterAndData: String? = (entryPoint.version == "0.6.0") ? "0x" : nil

        var userOperationStruct = UserOperationStruct(
            sender: address.asString(),
            nonce: nonce,
            initCode: initCode,
            callData: callData,
            signature: signature,
            paymasterAndData: initialPaymasterAndData
        )
        
        
        if entryPoint.version == "0.7.0" {
            if try await !account.isAccountDeployed() {
                userOperationStruct.factory = await account.getFactoryAddress()?.asString()
                userOperationStruct.factoryData = try await account.getFactoryData(initCode: userOperationStruct.initCode)
            }
        }

        return try await self.runMiddlewareStack(uoStruct: userOperationStruct, overrides: overrides ?? UserOperationOverrides())
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
            signature: Data(hex: uoToDrop.signature)!,
            paymasterAndData: uoToDrop.paymasterAndData,
            paymaster: uoToDrop.paymaster,
            paymasterData: uoToDrop.paymasterData,
            factory: uoToDrop.factory,
            factoryData: uoToDrop.factoryData
        )
        
        // Run once to get the fee estimates
        // This can happen at any part of the middleware stack, so we want to run it all
        let estimates = try await self.runMiddlewareStack(uoStruct: uoToSubmit, overrides: overrides ?? UserOperationOverrides())
        
        let newOverrides = UserOperationOverrides(
            maxFeePerGas: max(
                estimates.maxFeePerGas ?? BigUInt(0),
                bigIntPercent(
                    base: BigUInt(hex: uoToDrop.maxFeePerGas ?? "0x0")!,
                    percent: BigUInt(110)
                )
            ),
            maxPriorityFeePerGas: max(
                estimates.maxPriorityFeePerGas ?? BigUInt(0),
                bigIntPercent(
                    base: BigUInt(hex: uoToDrop.maxPriorityFeePerGas ?? "0x0")!,
                    percent: BigUInt(110)
                )
            )
        )

        let uoToSend = try await self.runMiddlewareStack(uoStruct: uoToSubmit, overrides: newOverrides)
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
    public func withPaymasterMiddleware(middleware: ClientMiddlewareFn?) -> ISmartAccountProvider {
        if let middleware = middleware {
            self.paymasterDataMiddleware = middleware
        }
        
        return self
    }
    
    @discardableResult
    public func withDummyPaymasterMiddleware(middleware: ClientMiddlewareFn?) -> ISmartAccountProvider {
        if let middleware = middleware {
            self.dummyPaymasterDataMiddleware = middleware
        }
        
        return self
    }
    
    @discardableResult
    public func withUserOperationSigner(signer: @escaping ClientMiddlewareFn) -> ISmartAccountProvider {
        self.userOperationSigner = signer
        return self
    }

    public func withMiddlewareRpcClient(rpcClient: BundlerClient) -> SmartAccountProvider {
        self.middlewareClient = rpcClient
        return self
    }
    
    private func runMiddlewareStack(
        uoStruct: UserOperationStruct,
        overrides: UserOperationOverrides
    ) async throws -> UserOperationStruct {
        
        guard let account = account else {
            throw SmartAccountProviderError.notConnected("Account not connected")
        }
        
        let paymasterData = if overrides.paymasterAndData != nil {
            overridePaymasterDataMiddleware
        } else {
            paymasterDataMiddleware
        }
        
        let asyncPipe = chain(paymasterData!, with:
                        chain(gasEstimator, with:
                        chain(feeDataGetter, with:
                              dummyPaymasterDataMiddleware)))
        let result = try await asyncPipe(middlewareClient ?? rpcClient, account, uoStruct, overrides)
        
        return result
    }

    // These are dependent on the specific paymaster being used
    // You should implement your own middleware to override these
    // or extend this class and provider your own implementation
    
    open func defaultDummyPaymasterDataMiddleware(
        client: BundlerClient,
        account: ISmartContractAccount,
        operation: UserOperationStruct,
        overrides: UserOperationOverrides
    ) async throws -> UserOperationStruct {
        var updatedOperation = operation
        let isV060 = (try? getEntryPoint().version) == "0.6.0"
        updatedOperation.paymasterAndData = isV060 ? "0x" : nil
        return updatedOperation
    }
    
    open func defaultOverridePaymasterDataMiddleware(
        client: BundlerClient,
        account: ISmartContractAccount,
        operation: UserOperationStruct,
        overrides: UserOperationOverrides
    ) async throws -> UserOperationStruct {
        var updatedOperation = operation
        let isV060 = (try? getEntryPoint().version) == "0.6.0"
        updatedOperation.paymasterAndData = overrides.paymasterAndData ?? (isV060 ? "0x" : nil)
        return updatedOperation
    }
    
    open func defaultPaymasterDataMiddleware(
        client: BundlerClient,
        account: ISmartContractAccount,
        operation: UserOperationStruct,
        overrides: UserOperationOverrides
    ) async throws -> UserOperationStruct {
        var updatedOperation = operation
        let isV060 = (try? getEntryPoint().version) == "0.6.0"
        updatedOperation.paymasterAndData = isV060 ? "0x" : nil
        return updatedOperation
    }
    
    open func defaultFeeDataGetter(
        client: BundlerClient,
        account: ISmartContractAccount,
        operation: UserOperationStruct,
        overrides: UserOperationOverrides
    ) async throws -> UserOperationStruct {
        var updatedOperation = operation
        // maxFeePerGas must be at least the sum of maxPriorityFeePerGas and baseFee
        // so we need to accommodate for the fee option applied maxPriorityFeePerGas for the maxFeePerGas
        //
        // Note that if maxFeePerGas is not at least the sum of maxPriorityFeePerGas and required baseFee
        // after applying the fee options, then the transaction will fail
        //
        // Refer to https://docs.alchemy.com/docs/maxpriorityfeepergas-vs-maxfeepergas
        // for more information about maxFeePerGas and maxPriorityFeePerGas
        if overrides.maxFeePerGas != nil && overrides.maxPriorityFeePerGas != nil {
            updatedOperation.maxFeePerGas = overrides.maxFeePerGas
            updatedOperation.maxPriorityFeePerGas = overrides.maxPriorityFeePerGas
            return updatedOperation
        }
        
        let feeData = try await rpcClient.estimateFeesPerGas(chain: chain)
        var maxPriorityFeePerGas = overrides.maxPriorityFeePerGas
        
        if maxPriorityFeePerGas == nil {
            maxPriorityFeePerGas = try await rpcClient.eth_maxPriorityFeePerGas()
        }
        
        let maxFeePerGas = overrides.maxFeePerGas ?? (feeData.maxFeePerGas - feeData.maxPriorityFeePerGas + maxPriorityFeePerGas!)

        updatedOperation.maxFeePerGas = maxFeePerGas
        updatedOperation.maxPriorityFeePerGas = maxPriorityFeePerGas

        return updatedOperation
    }
    
    public func getEntryPoint() throws -> EntryPoint {
        if let accountEntryPoint = self.account?.getEntryPoint() {
            return accountEntryPoint
        }

        return try Defaults.getDefaultEntryPoint(chain: chain)
    }
    
    public func getAddressForSigner(signerAddress: String) async throws -> EthereumAddress {
        guard let account = self.account else {
            throw SmartAccountProviderError.notConnected("Account not connected")
        }
        
        return try await account.getAddressForSigner(signerAddress: signerAddress)
    }

    private func sendUserOperation(uoStruct: UserOperationStruct) async throws -> SendUserOperationResult {
        guard let account = self.account else {
            throw SmartAccountProviderError.notConnected("Account not connected")
        }

        guard uoStruct.isValidRequest else {
            throw SmartAccountProviderError.noParameters("Request is missing parameters. All properties on UserOperationStruct must be set. struct: \(uoStruct)")
        }

        let uoStructSigned = try await userOperationSigner(middlewareClient ?? rpcClient, account, uoStruct, UserOperationOverrides())

        let address = try self.getEntryPoint().address
        let request = uoStructSigned.toUserOperationRequest()
        let uoHash = try await rpcClient!.sendUserOperation(request: request, entryPoint: address)
        
        return SendUserOperationResult(hash: uoHash, request: request)
    }
    
    private func chain<A, B, C, D>(_ f: @escaping (A, B, C, D) async throws -> C, with g: @escaping (A, B, C, D) async throws -> C) -> ((A, B, C, D) async throws -> C) {
        return { a, b, c, d in
            let result = try await g(a, b, c, d)
            return try await f(a, b, result, d)
        }
    }
}
