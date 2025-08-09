//
//  default7702Signer.swift
//  AA-Swift
//
//  Created by Andrei Ashikhmin on 26.07.2025.
//

import Foundation
import BigInt
import web3

/// EIP-7702 user operation signer
public func default7702UserOpSigner(
    client: BundlerClient,
    account: ISmartContractAccount,
    userOp: UserOperationStruct,
    overrides: UserOperationOverrides
) async throws -> UserOperationStruct {
    var uo = try await defaultUserOpSigner(client: client, account: account, userOp: userOp, overrides: overrides)
    
    var mutableAccount = account
    let accountAddress = try await mutableAccount.getAddress()
    let code = try await client.eth_getCode(address: accountAddress, block: .Latest)
    let implAddress = account.getImplementationAddress()
    let expectedCode = buildExpectedDelegationCode(implementationAddress: implAddress)
    
    if code.lowercased() == expectedCode.lowercased() {
        // Already delegated, no authorization needed
        uo.eip7702Auth = nil
        return uo
    }
    
    let accountNonce = try await client.eth_getTransactionCount(address: accountAddress, block: .Latest)
    guard let signer = account.getSigner() else {
        throw NSError(domain: "default7702Signer", code: 0, userInfo: [NSLocalizedDescriptionKey: "No signer available"])
    }
    let chainId = account.getEntryPoint().chain.id
    
    // Create authorization
    let authSignature = try await signer.signAuthorization(
        Authorization(
            chainId: chainId,
            contractAddress: implAddress,
            nonce: BigUInt(accountNonce)
        )
    )
    
    uo.eip7702Auth = Eip7702Auth(
        chainId: String(format: "0x%x", chainId),
        nonce: String(format: "0x%x", accountNonce),
        address: implAddress,
        r: authSignature.r,
        s: authSignature.s,
        yParity: authSignature.yParity
    )
    
    return uo
}

/// Builds the expected delegation code for EIP-7702
private func buildExpectedDelegationCode(implementationAddress: String) -> String {
    let cleanAddress = implementationAddress.replacingOccurrences(of: "0x", with: "").lowercased()
    return "0xef0100\(cleanAddress)"
}
