//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift
import web3
import BigInt

public struct AlchemyGasAndPaymasterAndData: Codable {
    private enum CodingKeys: String, CodingKey {
        case paymasterAndData
        case callGasLimitStr = "callGasLimit"
        case verificationGasLimitStr = "verificationGasLimit"
        case preVerificationGasStr = "preVerificationGas"
        case maxFeePerGasStr = "maxFeePerGas"
        case maxPriorityFeePerGasStr = "maxPriorityFeePerGas"
        case error
    }
    
    let paymasterAndData: String
    let callGasLimitStr: String
    let verificationGasLimitStr: String
    let preVerificationGasStr: String
    let maxFeePerGasStr: String
    let maxPriorityFeePerGasStr: String
    let error: ErrorObject?
    
    public var callGasLimit: BigUInt {
        return BigUInt(hex: callGasLimitStr)!
    }

    public var verificationGasLimit: BigUInt {
        return BigUInt(hex: verificationGasLimitStr)!
    }

    public var preVerificationGas: BigUInt {
        return BigUInt(hex: preVerificationGasStr)!
    }
    
    public var maxFeePerGas: BigUInt {
        return BigUInt(hex: maxFeePerGasStr)!
    }
    
    public var maxPriorityFeePerGas: BigUInt {
        return BigUInt(hex: maxPriorityFeePerGasStr)!
    }
}
