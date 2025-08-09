//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift
import web3
import BigInt

public struct AlchemyGasAndPaymasterAndData: Codable {
    public struct ErrorObject: Codable {
        public let code: Int
        public let message: String
        public let data: String?
        
        public init(code: Int, message: String, data: String? = nil) {
            self.code = code
            self.message = message
            self.data = data
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case paymaster
        case paymasterAndData
        case paymasterData
        case callGasLimitStr = "callGasLimit"
        case verificationGasLimitStr = "verificationGasLimit"
        case preVerificationGasStr = "preVerificationGas"
        case maxFeePerGasStr = "maxFeePerGas"
        case maxPriorityFeePerGasStr = "maxPriorityFeePerGas"
        case paymasterVerificationGasLimitStr = "paymasterVerificationGasLimit"
        case paymasterPostOpGasLimitStr = "paymasterPostOpGasLimit"
        case error
    }
    
    public let paymaster: String?
    public let paymasterAndData: String?
    public let paymasterData: String?
    public let callGasLimitStr: String?
    public let verificationGasLimitStr: String?
    public let preVerificationGasStr: String?
    public let maxFeePerGasStr: String?
    public let maxPriorityFeePerGasStr: String?
    public let paymasterVerificationGasLimitStr: String?
    public let paymasterPostOpGasLimitStr: String?
    public let error: ErrorObject?
    
    public var callGasLimit: BigUInt? {
        guard let limitStr = callGasLimitStr else { return nil }
        return BigUInt(hex: limitStr)
    }

    public var verificationGasLimit: BigUInt? {
        guard let limitStr = verificationGasLimitStr else { return nil }
        return BigUInt(hex: limitStr)
    }

    public var preVerificationGas: BigUInt? {
        guard let limitStr = preVerificationGasStr else { return nil }
        return BigUInt(hex: limitStr)
    }
    
    public var maxFeePerGas: BigUInt? {
        guard let feeStr = maxFeePerGasStr else { return nil }
        return BigUInt(hex: feeStr)
    }
    
    public var maxPriorityFeePerGas: BigUInt? {
        guard let feeStr = maxPriorityFeePerGasStr else { return nil }
        return BigUInt(hex: feeStr)
    }
    
    public var paymasterVerificationGasLimit: BigUInt? {
        guard let limitStr = paymasterVerificationGasLimitStr else { return nil }
        return BigUInt(hex: limitStr)
    }
    
    public var paymasterPostOpGasLimit: BigUInt? {
        guard let limitStr = paymasterPostOpGasLimitStr else { return nil }
        return BigUInt(hex: limitStr)
    }
    
    public init(
        paymaster: String? = nil,
        paymasterAndData: String? = nil,
        paymasterData: String? = nil,
        callGasLimitStr: String? = nil,
        verificationGasLimitStr: String? = nil,
        preVerificationGasStr: String? = nil,
        maxFeePerGasStr: String? = nil,
        maxPriorityFeePerGasStr: String? = nil,
        paymasterVerificationGasLimitStr: String? = nil,
        paymasterPostOpGasLimitStr: String? = nil,
        error: ErrorObject? = nil
    ) {
        self.paymaster = paymaster
        self.paymasterAndData = paymasterAndData
        self.paymasterData = paymasterData
        self.callGasLimitStr = callGasLimitStr
        self.verificationGasLimitStr = verificationGasLimitStr
        self.preVerificationGasStr = preVerificationGasStr
        self.maxFeePerGasStr = maxFeePerGasStr
        self.maxPriorityFeePerGasStr = maxPriorityFeePerGasStr
        self.paymasterVerificationGasLimitStr = paymasterVerificationGasLimitStr
        self.paymasterPostOpGasLimitStr = paymasterPostOpGasLimitStr
        self.error = error
    }
}
