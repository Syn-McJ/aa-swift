//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import web3
import Combine
import BigInt

public class LocalAccountSigner: SmartAccountSigner {
    public let signerType: String = "local"
    
    @Published private var _credentials: EthereumAccount?
    public var credentialsPublisher: AnyPublisher<EthereumAccount?, Never> {
        $_credentials.eraseToAnyPublisher()
    }
    
    public var account: EthereumAccount? {
        return _credentials
    }
    
    public static func privateKeyToAccountSigner(key: String) throws -> LocalAccountSigner {
        let keyStorage = EthereumKeyLocalStorage()
        let account = try EthereumAccount.importAccount(replacing: keyStorage, privateKey: key, keystorePassword: "")
        
        let signer = LocalAccountSigner()
        signer.setCredentials(account)
        return signer
    }
    
    public init() {
        // Initialize without account
    }
    
    public func setCredentials(_ credentials: EthereumAccount) {
        self._credentials = credentials
    }
    
    public func logout() {
        self._credentials = nil
    }
    
    public func getAddress() async throws -> String {
        guard let account = _credentials else {
            throw NSError(domain: "LocalAccountSigner", code: 0, userInfo: [NSLocalizedDescriptionKey: "Account not set"])
        }
        return account.address.asString()
    }
    
    public func signMessage(msg: Data) async throws -> Data {
        guard let account = _credentials else {
            throw NSError(domain: "LocalAccountSigner", code: 0, userInfo: [NSLocalizedDescriptionKey: "Account not set"])
        }
        let signed = try account.signMessage(message: msg)
        return signed.web3.hexData!
    }
    
    public func signAuthorization(_ authorization: Authorization) async throws -> AuthorizationSignature {
        guard let account = _credentials else {
            throw NSError(domain: "LocalAccountSigner", code: 0, userInfo: [NSLocalizedDescriptionKey: "Account not set"])
        }
        
        // EIP-7702 authorization hash calculation
        // keccak256(0x05 || rlp([chainId, contractAddress, nonce]))
        let encodedData = try encodeAuthorizationForSigning(authorization)
        let messageHash = encodedData.web3.keccak256

        // EIP-7702 uses raw message signing without prefix
        // IMPORTANT: Use sign(message:) not sign(data:) because sign(data:) hashes again!
        let signature = try account.sign(message: messageHash)
        
        // Extract r, s, and v components from the 65-byte signature
        guard signature.count == 65 else {
            throw NSError(domain: "LocalAccountSigner", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid signature length"])
        }
        
        let r = signature.prefix(32)
        let s = signature.dropFirst(32).prefix(32)
        let v = signature.last!

        // The secp256k1 library returns recid as 0 or 1 directly (not 27/28 like web3j)
        // So v is already the yParity value, no subtraction needed
        let yParity = String(format: "0x%x", v)
        
        let rHex = r.web3.hexString.hasPrefix("0x") ? String(r.web3.hexString.dropFirst(2)) : r.web3.hexString
        let sHex = s.web3.hexString.hasPrefix("0x") ? String(s.web3.hexString.dropFirst(2)) : s.web3.hexString
        return AuthorizationSignature(
            r: "0x" + rHex,
            s: "0x" + sHex,
            yParity: yParity
        )
    }
    
    /// Encodes authorization data for EIP-7702 signing
    /// EIP-7702 encoding: 0x05 prefix + RLP([chainId, contractAddress, nonce])
    private func encodeAuthorizationForSigning(_ authorization: Authorization) throws -> Data {
        // Prepare data for RLP encoding
        let chainIdData = BigInt(authorization.chainId)
        let contractAddressData = Data(hex: authorization.contractAddress.hasPrefix("0x") ?
            String(authorization.contractAddress.dropFirst(2)) : authorization.contractAddress)!
        let nonceData = authorization.nonce
        
        // Create RLP array: [chainId, contractAddress, nonce]
        let rlpArray: [Any] = [chainIdData, contractAddressData, nonceData]
        
        guard let rlpEncoded = RLP.encode(rlpArray) else {
            throw NSError(domain: "LocalAccountSigner", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to RLP encode authorization data"])
        }
        
        // Prepend 0x05 magic byte for EIP-7702
        var result = Data()
        result.append(0x05)
        result.append(rlpEncoded)
        
        return result
    }
}
