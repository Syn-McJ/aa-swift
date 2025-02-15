//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
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
