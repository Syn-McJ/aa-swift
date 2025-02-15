//
//  SponsoredUserOperation.swift
//  AA-Swift
//
//  Created by Andrei Ashikhmin on 7/2/25.
//

import BigInt

public struct ErrorObject: Equatable, Codable {
    public enum CodingKeys: String, CodingKey {
        case code
        case message
    }
    
    public let code: Int
    public let message: String
}

public struct SponsoredUserOperation: Equatable, Codable {
    public enum CodingKeys: String, CodingKey {
        case paymasterAndData
        case preVerificationGasStr = "preVerificationGas"
        case verificationGasLimitStr = "verificationGasLimit"
        case callGasLimitStr = "callGasLimit"
        case paymasterVerificationGasLimit
        case paymasterPostOpGasLimit
        case error
    }
    
    public let paymasterAndData: String
    let preVerificationGasStr: String
    let verificationGasLimitStr: String
    let callGasLimitStr: String
    public let paymasterVerificationGasLimit: String
    public let paymasterPostOpGasLimit: String
    public let error: ErrorObject?
    
    public var callGasLimit: BigUInt {
        return BigUInt(hex: callGasLimitStr)!
    }

    public var verificationGasLimit: BigUInt {
        return BigUInt(hex: verificationGasLimitStr)!
    }

    public var preVerificationGas: BigUInt {
        return BigUInt(hex: preVerificationGasStr)!
    }
}
