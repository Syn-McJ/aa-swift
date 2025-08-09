//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import BigInt
import web3

public typealias ClientMiddlewareFn = (BundlerClient, ISmartContractAccount, UserOperationStruct, UserOperationOverrides) async throws -> UserOperationStruct

// Based on https://github.com/alchemyplatform/aa-sdk/blob/main/packages/core/src/provider/types.ts#L95
public protocol ISmartAccountProvider {
    /// Boolean flag indicating if the account is connected
    var isConnected: Bool { get }

    /// Returns the address of the connected account
    func getAddress() async throws -> EthereumAddress
    
    /// Returns the address of the smart contract account for the specified signer
    func getAddressForSigner(signerAddress: String) async throws -> EthereumAddress

    /**
     Sends a user operation using the connected account.
     - Parameter data: `UserOperationCallData`
     - Parameter overrides: optional `UserOperationOverrides`
     - Returns: String containing the hash
    */
    func sendUserOperation(data: UserOperationCallData, overrides: UserOperationOverrides?) async throws -> SendUserOperationResult
    
    /**
     Sends a user operation using the connected account.
     - Parameter data: list of `UserOperationCallData`
     - Parameter overrides: optional `UserOperationOverrides`
     - Returns: String containing the hash
    */
    func sendUserOperation(data: [UserOperationCallData], overrides: UserOperationOverrides?) async throws -> SendUserOperationResult

    /**
     Allows you to get the unsigned UserOperation struct with all of the middleware run on it
     - Parameter data: UserOperationCallData
     - Parameter overrides: optional `UserOperationOverrides`
     - Returns: UserOperationStruct resulting from the middleware pipeline
    */
    func buildUserOperation(data: UserOperationCallData, overrides: UserOperationOverrides?) async throws -> UserOperationStruct
    
    /**
     Allows you to get the unsigned UserOperation struct with all of the middleware run on it
     - Parameter data: list of `UserOperationCallData`
     - Parameter overrides: optional `UserOperationOverrides`
     - Returns: UserOperationStruct resulting from the middleware pipeline
    */
    func buildUserOperation(data: [UserOperationCallData], overrides: UserOperationOverrides?) async throws -> UserOperationStruct
    
    /**
     Attempts to drop and replace an existing user operation by increasing fees
     - Parameter data: an existing user operation request returned by `sendUserOperation`
     - Parameter overrides: optional `UserOperationOverrides`
     - Returns: `SendUserOperationResult` containing the hash and request
    */
    func dropAndReplaceUserOperation(uoToDrop: UserOperationRequest, overrides: UserOperationOverrides?) async throws -> SendUserOperationResult

    /**
     Waits for the user operation to be included in a transaction that's been mined.
     - Parameter hash: The user operation hash you want to wait for
     - Returns: The receipt of the user operation
    */
    @discardableResult
    func waitForUserOperationTransaction(hash: String) async throws -> UserOperationReceipt

    // Middleware Overriders
    
    /// Overrides the feeDataGetter middleware for setting the fee fields on the UserOperation
    @discardableResult
    func withFeeDataGetter(feeDataGetter: @escaping ClientMiddlewareFn) -> ISmartAccountProvider

    /// Overrides the gasEstimator middleware for setting the gasLimit fields on the UserOperation
    @discardableResult
    func withGasEstimator(gasEstimator: @escaping ClientMiddlewareFn) -> ISmartAccountProvider

    /// Overrides the paymasterDataMiddleware middleware which is used for setting the paymasterAndData field on the UserOperation
    @discardableResult
    func withPaymasterMiddleware(middleware: ClientMiddlewareFn?) -> ISmartAccountProvider
    
    /// Overrides the dummyPaymasterDataMiddleware middleware which is used for setting dummy paymaster data during gas estimation
    @discardableResult
    func withDummyPaymasterMiddleware(middleware: ClientMiddlewareFn?) -> ISmartAccountProvider
    
    /// Overrides the userOperationSigner middleware which is used for signing the UserOperation
    @discardableResult
    func withUserOperationSigner(signer: @escaping ClientMiddlewareFn) -> ISmartAccountProvider
}
