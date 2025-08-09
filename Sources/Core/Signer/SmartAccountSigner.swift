//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation

/**
 * A signer that can sign messages and typed data.
 *
 * @template Inner - the generic type of the inner client that the signer wraps to provide functionality such as signing, etc.
 *
 * @var signerType - the type of the signer (e.g. local, hardware, etc.)
 * @var inner - the inner client of @type {Inner}
 *
 * @method getAddress - get the address of the signer
 * @method signMessage - sign a message
 * @method signAuthorization - sign an EIP-7702 authorization for account delegation
 */
public protocol SmartAccountSigner {
    /// The type of the signer (e.g., local, hardware, etc.)
    var signerType: String { get }
    
    /// Get the address of the signer
    func getAddress() async -> String
    /// Sign a message
    func signMessage(msg: Data) async throws -> Data
    /// Sign an EIP-7702 authorization for account delegation
    func signAuthorization(_ authorization: Authorization) async throws -> AuthorizationSignature
}
