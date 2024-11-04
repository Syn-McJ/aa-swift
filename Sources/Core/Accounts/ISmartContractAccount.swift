//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import BigInt
import web3

public protocol ISmartContractAccount {
    /// Returns the init code for the account
    mutating func getInitCode() async throws -> String

    /// Returns a dummy signature that doesn't cause the account to revert during estimation
    func getDummySignature() -> Data

    /// Encodes a call to the account's execute function
    func encodeExecute(target: EthereumAddress, value: BigUInt, data: Data) async -> String

    /// Encodes a batch of transactions to the account's batch execute function
    func encodeBatchExecute(txs: [UserOperationCallData]) async -> String

    /// Returns the nonce of the account
    mutating func getNonce() async throws -> BigUInt

    /// Returns a signed and prefixed message
    func signMessage(msg: Data) async throws -> Data

    /// If the account is not deployed, it will sign the message and then wrap it in 6492 format
    func signMessageWith6492(msg: Data) async -> Data

    /// Returns the address of the account
    mutating func getAddress() async throws -> EthereumAddress
    
    /// Returns the address of the smart contract account for the specified signer
    func getAddressForSigner(signerAddress: String) async throws -> EthereumAddress

    /// Returns the smart contract account owner instance if it exists
    func getOwner() async -> SmartAccountSigner?

    /// Returns the address of the factory contract for the smart contract account
    func getFactoryAddress() async -> EthereumAddress

    /// Returns the address of the entry point contract for the smart contract account
    func getEntryPointAddress() throws -> EthereumAddress
}
