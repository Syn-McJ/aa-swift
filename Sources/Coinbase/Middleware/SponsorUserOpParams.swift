//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift

public struct SponsorUserOpParams: Equatable, Encodable {
    public let userOperation: UserOperationRequest
    public let entryPoint: String
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(userOperation)
        try container.encode(entryPoint)
    }
}
