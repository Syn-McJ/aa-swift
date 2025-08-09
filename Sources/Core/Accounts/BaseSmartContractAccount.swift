//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import web3
import BigInt

public enum BaseSCAError: Error {
    case counterfactualAddress(String)
}

public enum DeploymentState: String {
    case undefined = "0x0"
    case notDeployed = "0x1"
    case deployed = "0x2"
}

/// Base class implementation of ISmartContractAccount
open class BaseSmartContractAccount: ISmartContractAccount {
    public let rpcClient: EthereumRPCProtocol
    public let signer: SmartAccountSigner
    public var deploymentState: DeploymentState
    public let entryPoint: EntryPoint?
    public let chain: Chain
    public var accountAddress: EthereumAddress?
    
    public init(
        rpcClient: EthereumRPCProtocol,
        signer: SmartAccountSigner,
        chain: Chain,
        entryPoint: EntryPoint? = nil,
        accountAddress: EthereumAddress? = nil
    ) {
        self.rpcClient = rpcClient
        self.signer = signer
        self.chain = chain
        self.entryPoint = entryPoint
        self.accountAddress = accountAddress
        self.deploymentState = .undefined
    }
    
    // This method must be overridden by subclasses
    open func getAccountInitCode(forAddress: String) async -> String {
        fatalError("getAccountInitCode must be implemented by subclass")
    }
    
    // Concrete implementations of protocol methods
    open func getAddress() async throws -> EthereumAddress {
        if let address = self.accountAddress {
            return address
        }
        
        let signerAddress = await signer.getAddress()
        let address = try await getAddressForSigner(signerAddress: signerAddress)
        self.accountAddress = address
        
        return address
    }
    
    open func getAddressForSigner(signerAddress: String) async throws -> EthereumAddress {
        let initCode = await getAccountInitCode(forAddress: signerAddress)
        let encodedCall = encodeGetSenderAddress(initCode: initCode)
        
        let transaction = EthereumTransaction(
            from: EthereumAddress(signerAddress),
            to: try getEntryPointAddress(),
            data: encodedCall,
            gasPrice: BigUInt(0),
            gasLimit: BigUInt(0)
        )
        
        do {
            let _ = try await rpcClient.eth_call(transaction, block: EthereumBlock.Latest)
        } catch {
            switch error {
            case EthereumClientError.executionError(let details):
                let trimmedResult = details.data!.trimmingCharacters(in: CharacterSet(charactersIn: "\" "))
                let addressString = "0x" + trimmedResult.suffix(40)
                return EthereumAddress(addressString)
            default:
                break;
            }
        }
        
        throw BaseSCAError.counterfactualAddress("Failed to get smart contract account address")
    }
    
    public func encodeGetSenderAddress(initCode: String) -> Data {
        let function = ABIFunctionEncoder("getSenderAddress")
        try! function.encode(Data(hex: initCode)!)
        return try! function.encoded()
    }
    
    // Abstract methods that must be implemented by subclasses
    open func getDummySignature() -> Data {
        fatalError("getDummySignature must be implemented by subclass")
    }
    
    open func encodeExecute(target: EthereumAddress, value: BigUInt, data: Data) async -> String {
        fatalError("encodeExecute must be implemented by subclass")
    }
    
    open func encodeBatchExecute(txs: [UserOperationCallData]) async -> String {
        fatalError("encodeBatchExecute must be implemented by subclass")
    }
    
    open func signMessage(msg: Data) async throws -> Data {
        fatalError("signMessage must be implemented by subclass")
    }
    
    open func signMessageWith6492(msg: Data) async -> Data {
        fatalError("signMessageWith6492 must be implemented by subclass")
    }
    
    open func getFactoryAddress() async -> EthereumAddress? {
        fatalError("getFactoryAddress must be implemented by subclass")
    }
    
    open func getFactoryData(initCode: String?) async throws -> String? {
        fatalError("getFactoryData must be implemented by subclass")
    }
    
    open func getSigner() -> SmartAccountSigner? {
        return signer
    }
    
    open func getEntryPoint() -> EntryPoint {
        if let entryPoint = entryPoint {
            return entryPoint
        }
        // Return default entry point for the chain
        return try! Defaults.getDefaultEntryPoint(chain: chain)
    }
    
    open func getImplementationAddress() -> String {
        fatalError("getFactoryAddress must be implemented by subclass")
    }
    
    // Methods that use default implementations from extension but need to be in base class
    open func getNonce() async throws -> BigUInt {
        let isDeployed = try await isAccountDeployed()
        
        if (!isDeployed) {
            return BigUInt(0)
        }

        return try await getNonce(nonceKey: BigUInt(0))
    }
    
    open func getNonce(nonceKey: BigUInt) async throws -> BigUInt {
        let address = try await getAddress()
        let function = ABIFunctionEncoder("getNonce")
        try function.encode(address)
        try function.encode(nonceKey, staticSize: 192)
        let encodedCall = try function.encoded()
        let signerAddress = await signer.getAddress()
        
        let transaction = EthereumTransaction(
            from: EthereumAddress(signerAddress),
            to: try getEntryPointAddress(),
            data: encodedCall,
            gasPrice: BigUInt(0),
            gasLimit: BigUInt(0)
        )
        
        let result = try await rpcClient.eth_call(transaction, block: EthereumBlock.Latest)
        
        return BigUInt(hex: result)!
    }
    
    open func isAccountDeployed() async throws -> Bool {
        try await getDeploymentState() == .deployed
    }

    open func getDeploymentState() async throws -> DeploymentState {
        if self.deploymentState == .undefined {
            return try await getInitCode() == "0x" ? .deployed : .notDeployed
        } else {
            return self.deploymentState
        }
    }
    
    open func getInitCode() async throws -> String {
        if self.deploymentState == .deployed {
            return "0x"
        }

        let address = try await getAddress()
        let contractCode = try await rpcClient.eth_getCode(address: address, block: .Latest)

        if contractCode.count > 2 {
            self.deploymentState = .deployed
            return "0x"
        } else {
            self.deploymentState = .notDeployed
        }

        return await getAccountInitCode(forAddress: await signer.getAddress())
    }
    
    public func getEntryPointAddress() throws -> EthereumAddress {
        if let address = entryPoint?.address {
            return EthereumAddress(address)
        }
        
        return EthereumAddress(getEntryPoint().address)
    }
}
