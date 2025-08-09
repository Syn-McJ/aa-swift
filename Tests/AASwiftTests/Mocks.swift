//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import MockSwift
import web3
import Foundation
@testable import AASwift

extension Mock: EthereumRPCProtocol where WrappedType == EthereumRPCProtocol {
    public var networkProvider: web3.NetworkProviderProtocol {
        fatalError("Not implemented")
    }
    
    public var network: web3.EthereumNetwork {
        fatalError("Not implemented")
    }
    
    public func eth_call(_ transaction: web3.EthereumTransaction, block: web3.EthereumBlock) async throws -> String {
        fatalError("Not implemented")
    }
    
    public func eth_call(_ transaction: web3.EthereumTransaction, resolution: web3.CallResolution, block: web3.EthereumBlock) async throws -> String {
        fatalError("Not implemented")
    }
}

extension Mock: SmartAccountSigner where WrappedType == SmartAccountSigner {
    public var signerType: String {
        "local"
    }
    
    public func getAddress() async -> String {
        "0x29DF43F75149D0552475A6f9B2aC96E28796ed0b"
    }
    
    public func signMessage(msg: Data) async -> Data {
        return Data(hex: "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789")!
    }
    
    public func signAuthorization(_ authorization: Authorization) async throws -> AuthorizationSignature {
        return AuthorizationSignature(
            r: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
            s: "0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
            yParity: "0x0"
        )
    }
}
