//
//  SponsorUserOpParams.swift
//  AA-Swift
//
//  Created by Andrei Ashikhmin on 8/2/25.
//
import AASwift

struct SponsorUserOpParams: Equatable, Encodable {
    public let userOperation: UserOperationRequest
    public let entryPoint: String
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(userOperation)
        try container.encode(entryPoint)
    }
}
