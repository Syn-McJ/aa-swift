//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import web3
import AASwift
import BigInt

/// Alchemy's ModularAccountV2 implementation supporting both ERC-4337 and EIP-7702
public class ModularAccountV2: BaseSmartContractAccount {
    /// ModularAccountV2 implementation contract address for EIP-7702 delegation
    public static let IMPLEMENTATION_ADDRESS = "0x69007702764179f14F51cdce752f4f775d74E139"
    
    /// Default factory address for ModularAccountV2 when using ERC-4337 mode
    private static let DEFAULT_FACTORY_ADDRESS = "0x00000000000017c61b5bEe81050EC8eFc9c6fecd"
    
    private static let DEFAULT_OWNER_ENTITY_ID = 0
    
    private let factoryAddress: EthereumAddress?
    private let mode: AccountMode
    
    public init(
        rpcClient: EthereumRPCProtocol,
        factoryAddress: EthereumAddress? = nil,
        signer: SmartAccountSigner,
        chain: Chain,
        mode: AccountMode = .DEFAULT,
        accountAddress: EthereumAddress? = nil
    ) {
        self.factoryAddress = factoryAddress
        self.mode = mode
        
        let entryPoint = try? Defaults.getV7EntryPoint(chain: chain)
        super.init(
            rpcClient: rpcClient,
            signer: signer,
            chain: chain,
            entryPoint: entryPoint,
            accountAddress: accountAddress
        )
    }
    
    /// Get the account mode (ERC-4337 or EIP-7702)
    public func getMode() -> AccountMode {
        return mode
    }
    
    public override func getAccountInitCode(forAddress: String) async -> String {
        switch mode {
        case .EIP7702:
            return "0x"
        case .DEFAULT:
            // ERC-4337 mode: use factory to create account
            let factory = factoryAddress?.asString() ?? ModularAccountV2.DEFAULT_FACTORY_ADDRESS
            
            let function = ABIFunctionEncoder("createSemiModularAccount")
            try! function.encode(EthereumAddress(forAddress))
            try! function.encode(BigUInt(0)) // salt
            let encodedData = try! function.encoded()
            
            return factory + encodedData.web3.hexString.dropFirst(2)
        }
    }
    
    public override func getAddress() async throws -> EthereumAddress {
        switch mode {
        case .EIP7702:
            // EIP-7702 uses the signer's EOA address directly
            return EthereumAddress(await signer.getAddress())
        case .DEFAULT:
            // ERC-4337 uses counterfactual address calculation
            if let address = self.accountAddress {
                return address
            }
            
            let signerAddress = await signer.getAddress()
            let address = try await getAddressForSigner(signerAddress: signerAddress)
            self.accountAddress = address
            
            return address
        }
    }
    
    public override func getAddressForSigner(signerAddress: String) async throws -> EthereumAddress {
        switch mode {
        case .EIP7702:
            // EIP-7702 uses the signer's EOA address directly
            let address = await signer.getAddress()
            
            if address != signerAddress {
                throw BaseSCAError.counterfactualAddress("signerAddress parameter and the address of account's signer must match")
            }
            
            return EthereumAddress(signerAddress)
        case .DEFAULT:
            // ERC-4337 uses counterfactual address calculation
            return try await super.getAddressForSigner(signerAddress: signerAddress)
        }
    }
    
    public override func getNonce() async throws -> BigUInt {
        return try await getNonce(nonceKey: buildFullNonceKey(
            nonceKey: 0,
            entityId: ModularAccountV2.DEFAULT_OWNER_ENTITY_ID,
            isGlobalValidation: true,
            isDeferredAction: false
        ))
    }
    
    private func buildFullNonceKey(
        nonceKey: Int = 0,
        entityId: Int = 0,
        isGlobalValidation: Bool = true,
        isDeferredAction: Bool = false
    ) -> BigUInt {
        let nonceKeyBigInt = BigUInt(nonceKey) << 40 // Shift nonce key left by 40 bits
        let entityIdBigInt = BigUInt(entityId) << 8  // Entity ID in bits 8-39
        let deferredActionBit = isDeferredAction ? BigUInt(2) : BigUInt(0) // Deferred action flag
        let globalValidationBit = isGlobalValidation ? BigUInt(1) : BigUInt(0) // Global validation flag
        
        return nonceKeyBigInt + entityIdBigInt + deferredActionBit + globalValidationBit
    }
    
    /// Returns the implementation address for EIP-7702 accounts
    public override func getImplementationAddress() -> String {
        return ModularAccountV2.IMPLEMENTATION_ADDRESS
    }
    
    /// Get the account signer
    public override func getSigner() -> SmartAccountSigner? {
        return signer
    }
    
    public override func isAccountDeployed() async throws -> Bool {
        try await getDeploymentState() == .deployed
    }
    
    public override func getDummySignature() -> Data {
        let dummySig = "0xFF00fffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c"
        return Data(hex: dummySig)!
    }
    
    public override func signMessage(msg: Data) async throws -> Data {
        let signature = try await signer.signMessage(msg: msg)
        return packUOSignature(sig: signature)
    }
    
    public override func signMessageWith6492(msg: Data) async -> Data {
        fatalError("Not yet implemented")
    }
    
    public override func getFactoryAddress() async -> EthereumAddress? {
        guard mode == .DEFAULT else {
            return nil
        }
        
        return factoryAddress ?? EthereumAddress(ModularAccountV2.DEFAULT_FACTORY_ADDRESS)
    }
    
    override public func getFactoryData(initCode: String?) async throws -> String? {
        guard mode == .DEFAULT else {
            return nil
        }
        
        let resolvedInitCode: String
        if let initCode = initCode {
            resolvedInitCode = initCode
        } else {
            resolvedInitCode = try await getInitCode()
        }
        return parseFactoryAddressFromAccountInitCode(initCode: resolvedInitCode).factoryCalldata
    }
    
    public override func encodeExecute(target: EthereumAddress, value: BigUInt, data: Data) async -> String {
        let function = ABIFunctionEncoder("execute")
        try! function.encode(target)
        try! function.encode(value)
        try! function.encode(data)
        
        return try! function.encoded().web3.hexString
    }
    
    public override func encodeBatchExecute(txs: [UserOperationCallData]) async -> String {
        // ModularAccountV2 supports batch execution through executeBatch function
        let function = ABIFunctionEncoder("executeBatch")
        
        // Create array of tuples
        let tuples = txs.map { tx in
            ExecuteBatchTuple(
                target: tx.target,
                value: tx.value ?? BigUInt(0),
                data: tx.data
            )
        }
        
        // Encode the array of tuples
        try! function.encode(tuples)
        
        return try! function.encoded().web3.hexString
    }
    
    private func packUOSignature(sig: Data) -> Data {
        var packed = Data()
        packed.append(0xFF)
        packed.append(0x00)
        packed.append(sig)
        return packed
    }
    
    /// Parses the factory address and factory calldata from the provided account initialization code (initCode).
    private func parseFactoryAddressFromAccountInitCode(initCode: String) -> (factoryAddress: String, factoryCalldata: String) {
        guard initCode.count >= 44 else {
            return ("0x", "0x")
        }
        
        let cleanedInitCode = initCode.hasPrefix("0x") ? String(initCode.dropFirst(2)) : initCode
        let factoryAddress = "0x" + String(cleanedInitCode.prefix(40))
        let factoryCalldata = "0x" + String(cleanedInitCode.dropFirst(40))
        
        return (factoryAddress, factoryCalldata)
    }
    
    public override func getDeploymentState() async throws -> DeploymentState {
        if self.deploymentState == .undefined {
            return try await getInitCode() == "0x" ? .deployed : .notDeployed
        } else {
            return self.deploymentState
        }
    }
    
    private func encodeGetSenderAddressData(initCode: String) -> Data {
        let function = ABIFunctionEncoder("getSenderAddress")
        try! function.encode(Data(hex: initCode)!)
        return try! function.encoded()
    }
}
