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
    public let factoryAddress: EthereumAddress
    private let index: Int64?
    
    public init(rpcClient: EthereumRPCProtocol, entryPoint: EntryPoint? = nil, factoryAddress: EthereumAddress, signer: SmartAccountSigner, chain: Chain, accountAddress: EthereumAddress? = nil, index: Int64? = nil) {
        self.factoryAddress = factoryAddress
        self.index = index
        
        super.init(
            rpcClient: rpcClient,
            signer: signer,
            chain: chain,
            entryPoint: entryPoint,
            accountAddress: accountAddress
        )
        
        self.deploymentState = .notDeployed
    }
    
    open override func getAccountInitCode(forAddress: String) async -> String {
        let fn = ABIFunctionEncoder("createAccount")
        try! fn.encode(EthereumAddress(forAddress))
        try! fn.encode(BigUInt(index ?? 0))

        return concatHex(values: [
            factoryAddress.asString(),
            try! fn.encoded().web3.hexString
        ])
    }
    
    public override func getDummySignature() -> Data {
        Data(hex: "0xfffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c"
        )!
    }
    
    public override func encodeExecute(target: EthereumAddress, value: BigUInt, data: Data) async -> String {
        let encodedFn = ABIFunctionEncoder("execute")
        try! encodedFn.encode(target)
        try! encodedFn.encode(value)
        try! encodedFn.encode(data)
        
        return try! encodedFn.encoded().web3.hexString
    }
    
    public override func encodeBatchExecute(txs: [UserOperationCallData]) async -> String {
        let targets = txs.map { $0.target }
        let datas = txs.map { $0.data }
        
        let encodedFn = ABIFunctionEncoder("executeBatch")
        try! encodedFn.encode(targets)
        try! encodedFn.encode(datas)
        
        return try! encodedFn.encoded().web3.hexString
    }
    
    public override func signMessage(msg: Data) async throws -> Data {
        try await signer.signMessage(msg: msg)
    }
    
    public override func signMessageWith6492(msg: Data) async -> Data {
        fatalError("Not yet implemented")
    }
    
    public override func getSigner() -> SmartAccountSigner? {
        return signer
    }
    
    public override func getFactoryAddress() async -> EthereumAddress {
        return factoryAddress
    }
    
    public override func getImplementationAddress() -> String {
        fatalError("Not yet implemented")
    }
}
