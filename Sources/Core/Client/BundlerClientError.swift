//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import web3

/// A wrapper error that includes the RPC method name along with the underlying error
public struct BundlerClientError: Error, CustomStringConvertible {
    /// The name of the RPC method that failed
    public let methodName: String
    
    /// The underlying Ethereum client error
    public let underlyingError: EthereumClientError
    
    public init(methodName: String, underlyingError: EthereumClientError) {
        self.methodName = methodName
        self.underlyingError = underlyingError
    }
    
    public var description: String {
        return "BundlerClientError in method '\(methodName)': \(underlyingError)"
    }
}
