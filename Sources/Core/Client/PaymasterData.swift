//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import web3
import Foundation
import BigInt

public struct ErrorObject: Equatable, Codable {
    public enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
    }
    
    public let code: Int
    public let message: String
    public let data: String?
    
    public init(code: Int, message: String, data: String? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}

public struct Sponsor: Equatable, Codable {
    public enum CodingKeys: String, CodingKey {
        case name
        case icon
    }
    
    public let name: String?
    public let icon: String?
    
    public init(name: String? = nil, icon: String? = nil) {
        self.name = name
        self.icon = icon
    }
}

public struct PaymasterData: Equatable, Codable {
    public let paymaster: String?
    public let paymasterData: String?
    public let paymasterAndData: String?
    private let paymasterVerificationGasLimitStr: String?
    private let paymasterPostOpGasLimitStr: String?
    public let sponsor: Sponsor?
    public let error: ErrorObject?

    public enum CodingKeys: String, CodingKey {
        case paymaster
        case paymasterData
        case paymasterAndData
        case paymasterVerificationGasLimitStr = "paymasterVerificationGasLimit"
        case paymasterPostOpGasLimitStr = "paymasterPostOpGasLimit"
        case sponsor
        case error
    }
    
    public init(
        paymaster: String? = nil,
        paymasterData: String? = nil,
        paymasterAndData: String? = nil,
        paymasterVerificationGasLimit: String? = nil,
        paymasterPostOpGasLimit: String? = nil,
        sponsor: Sponsor? = nil,
        error: ErrorObject? = nil
    ) {
        self.paymaster = paymaster
        self.paymasterData = paymasterData
        self.paymasterAndData = paymasterAndData
        self.paymasterVerificationGasLimitStr = paymasterVerificationGasLimit
        self.paymasterPostOpGasLimitStr = paymasterPostOpGasLimit
        self.sponsor = sponsor
        self.error = error
    }
    
    /// Computed property to convert paymasterVerificationGasLimit from hex string to BigUInt
    public var paymasterVerificationGasLimit: BigUInt? {
        guard let hexString = paymasterVerificationGasLimitStr else { return nil }
        return BigUInt(hex: hexString)
    }
    
    /// Computed property to convert paymasterPostOpGasLimit from hex string to BigUInt
    public var paymasterPostOpGasLimit: BigUInt? {
        guard let hexString = paymasterPostOpGasLimitStr else { return nil }
        return BigUInt(hex: hexString)
    }
}
