//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import web3
import BigInt

open class SimpleSmartContractAccount: BaseSmartContractAccount {
    public let chain: Chain
    public let signer: SmartAccountSigner
    public let rpcClient: EthereumRPCProtocol
    public let entryPointAddress: EthereumAddress?
    public let factoryAddress: EthereumAddress
    
    public var deploymentState: DeploymentState
    public var accountAddress: EthereumAddress?
    
    private let index: Int64?
    
    public init(rpcClient: EthereumRPCProtocol, entryPointAddress: EthereumAddress? = nil, factoryAddress: EthereumAddress, signer: SmartAccountSigner, chain: Chain, accountAddress: EthereumAddress? = nil, index: Int64? = nil) {
        self.rpcClient = rpcClient
        self.signer = signer
        self.entryPointAddress = entryPointAddress
        self.factoryAddress = factoryAddress
        self.chain = chain
        self.accountAddress = accountAddress
        self.index = index
        self.deploymentState = .notDeployed
    }
    
    open func getAccountInitCode(forAddress: String) async -> String {
        let fn = ABIFunctionEncoder("createAccount")
        try! fn.encode(EthereumAddress(forAddress))
        try! fn.encode(BigUInt(index ?? 0))

        return concatHex(values: [
            factoryAddress.asString(),
            try! fn.encoded().web3.hexString
        ])
    }
    
    public func getDummySignature() -> Data {
        Data(hex: "0xfffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c"
        )!
    }
    
    public func encodeExecute(target: EthereumAddress, value: BigUInt, data: Data) async -> String {
        let encodedFn = ABIFunctionEncoder("execute")
        try! encodedFn.encode(target)
        try! encodedFn.encode(value)
        try! encodedFn.encode(data)
        
        return try! encodedFn.encoded().web3.hexString
    }
    
    public func encodeBatchExecute(txs: [UserOperationCallData]) async -> String {
        let targets = txs.map { $0.target }
        let datas = txs.map { $0.data }
        
        let encodedFn = ABIFunctionEncoder("executeBatch")
        try! encodedFn.encode(targets)
        try! encodedFn.encode(datas)
        
        return try! encodedFn.encoded().web3.hexString
    }
    
    public func signMessage(msg: Data) async throws -> Data {
        try await signer.signMessage(msg: msg)
    }
    
    public func signMessageWith6492(msg: Data) async -> Data {
        fatalError("Not yet implemented")
    }
    
    public func getOwner() async -> SmartAccountSigner? {
        return signer
    }
    
    public func getFactoryAddress() async -> EthereumAddress {
        return factoryAddress
    }
}
