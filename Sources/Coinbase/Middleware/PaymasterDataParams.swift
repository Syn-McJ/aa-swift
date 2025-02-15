//
//  SponsoredUserOperation.swift
//  AA-Swift
//
//  Created by Andrei Ashikhmin on 7/2/25.
//

import AASwift

public struct Policy: Equatable, Encodable {
    public let policyId: String
}

public struct PaymasterDataParams: Equatable, Encodable {
    public let userOperation: UserOperationRequest
    public let entryPoint: String
    public let chainId: String
    public let policy: Policy
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(userOperation)
        try container.encode(entryPoint)
        try container.encode(chainId)
        try container.encode(policy)
    }
}
