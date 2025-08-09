//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation

/// Account mode enumeration for different account types
public enum AccountMode {
    /// Traditional ERC-4337 smart contract account
    case DEFAULT
    /// EIP-7702 delegated EOA account
    case EIP7702
}