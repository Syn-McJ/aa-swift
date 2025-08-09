//
//  defaultUserOpSigner.swift
//  AA-Swift
//
//  Created by Andrei Ashikhmin on 26.07.2025.
//

import web3

public func defaultUserOpSigner(client: BundlerClient, account: ISmartContractAccount, userOp: UserOperationStruct, overrides: UserOperationOverrides) async throws -> UserOperationStruct {
    var updatedUserOp = userOp
    let uoHash = getUserOperationHash(
        request: updatedUserOp,
        entryPoint: account.getEntryPoint(),
        chainId: account.getEntryPoint().chain.id
    )
    
    updatedUserOp.signature = try await account.signMessage(msg: uoHash)
    
    return updatedUserOp
}
