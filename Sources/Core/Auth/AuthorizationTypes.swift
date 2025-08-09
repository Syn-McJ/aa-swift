//
//  AuthorizationTypes.swift
//  AA-Swift
//
//  Created by Andrei Ashikhmin on 26.07.2025.
//

import BigInt

/// EIP-7702 Authorization tuple for account delegation
public struct Eip7702Auth: Codable, Equatable {
    /// Chain ID for the authorization
    public let chainId: String
    /// Nonce for the authorization
    public let nonce: String
    /// Implementation contract address to delegate to
    public let address: String
    /// Signature r component
    public let r: String
    /// Signature s component
    public let s: String
    /// Signature yParity component (0 or 1)
    public let yParity: String
    
    public init(chainId: String, nonce: String, address: String, r: String, s: String, yParity: String) {
        self.chainId = chainId
        self.nonce = nonce
        self.address = address
        self.r = r
        self.s = s
        self.yParity = yParity
    }
}

/// Authorization data structure for EIP-7702 delegation
public struct Authorization: Codable {
    /// Chain ID where the authorization is valid
    public let chainId: Int64
    /// Implementation contract address to delegate execution to
    public let contractAddress: String
    /// Account nonce for replay protection
    public let nonce: BigUInt
    
    public init(chainId: Int64, contractAddress: String, nonce: BigUInt) {
        self.chainId = chainId
        self.contractAddress = contractAddress
        self.nonce = nonce
    }
}

/// Authorization signature components
public struct AuthorizationSignature: Codable {
    /// Signature r component
    public let r: String
    /// Signature s component
    public let s: String
    /// Recovery ID / yParity (0 or 1)
    public let yParity: String
    
    public init(r: String, s: String, yParity: String) {
        self.r = r
        self.s = s
        self.yParity = yParity
    }
}
