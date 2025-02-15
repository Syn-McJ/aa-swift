//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
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
