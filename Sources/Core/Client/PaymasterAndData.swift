//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import web3
import Foundation

public struct ErrorObject: Equatable, Codable {
    public enum CodingKeys: String, CodingKey {
        case code
        case message
    }
    
    public let code: Int
    public let message: String
}

public struct PaymasterAndData: Equatable, Codable {
    public let paymasterAndData: String
    public let error: ErrorObject?

    public enum CodingKeys: String, CodingKey {
        case paymasterAndData
        case error
    }
}
