//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import BigInt
import web3


 /// Provides a default middleware function for signing user operations with a client account when using EIP-7702 delegated accounts.
 /// If the signer doesn't support `signAuthorization`, then this just runs the provided `signUserOperation` middleware.
 /// This function is only compatible with accounts using EntryPoint v0.7.0, and the account must have an implementation address defined in `getImplementationAddress()`.
public func default7702GasEstimator(
    client: BundlerClient,
    account: ISmartContractAccount,
    userOp: UserOperationStruct,
    overrides: UserOperationOverrides,
    continued: ClientMiddlewareFn
) async throws -> UserOperationStruct {
    let entryPoint = account.getEntryPoint()
    
    if entryPoint.version != "0.7.0" {
        return try await continued(client, account, userOp, overrides)
    }
    
    let implementationAddress = account.getImplementationAddress()
    
    // Note: does not omit the delegation from estimation if the account is already 7702 delegated.
    var updatedUserOp = userOp
    updatedUserOp.initCode = nil
    updatedUserOp.eip7702Auth = Eip7702Auth(
        chainId: "0x0",
        nonce: "0x0",
        address: implementationAddress,
        r: "0x0000000000000000000000000000000000000000000000000000000000000000",
        s: "0x0000000000000000000000000000000000000000000000000000000000000000",
        yParity: "0x0"
    )
    
    return try await continued(client, account, updatedUserOp, overrides)
}
