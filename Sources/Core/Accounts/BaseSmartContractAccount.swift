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

public protocol BaseSmartContractAccount: ISmartContractAccount {
    var rpcClient: EthereumRPCProtocol { get }
    var signer: SmartAccountSigner { get }
    var deploymentState: DeploymentState { get set }
    var entryPointAddress: EthereumAddress? { get }
    var chain: Chain { get }
    var accountAddress: EthereumAddress? { get set }
    
    func getAccountInitCode(forAddress: String) async -> String
}

extension BaseSmartContractAccount {
    public mutating func getInitCode() async throws -> String {
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
    
    public mutating func getNonce() async throws -> BigUInt {
        let isDeployed = try await isAccountDeployed()
        
        if (!isDeployed) {
            return BigUInt(0)
        }

        let address = try await getAddress()
        let function = ABIFunctionEncoder("getNonce")
        try function.encode(address)
        try function.encode(BigUInt(0), staticSize: 192)
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
    
    public mutating func getAddress() async throws -> EthereumAddress {
        if let address = self.accountAddress {
            return address
        }
        
        let signerAddress = await signer.getAddress()
        let address = try await getAddressForSigner(signerAddress: signerAddress)
        self.accountAddress = address
        
        return address
    }
    
    public func getAddressForSigner(signerAddress: String) async throws -> EthereumAddress {
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
    
    public func getEntryPointAddress() throws -> EthereumAddress {
        if let address = entryPointAddress {
            return address
        }
        
        return try chain.getDefaultEntryPointAddress()
    }
    
    func encodeGetSenderAddress(initCode: String) -> Data {
        let function = ABIFunctionEncoder("getSenderAddress")
        try! function.encode(Data(hex: initCode)!)
        return try! function.encoded()
    }
    
    private mutating func isAccountDeployed() async throws -> Bool {
        try await getDeploymentState() == .deployed
    }

    private mutating func getDeploymentState() async throws -> DeploymentState {
        if self.deploymentState == .undefined {
            return try await getInitCode() == "0x" ? .deployed : .notDeployed
        } else {
            return self.deploymentState
        }
    }
}
