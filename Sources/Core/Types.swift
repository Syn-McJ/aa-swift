//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import BigInt
import web3

/// Custom Address type that enforces 0x prefix validation
public struct Address: Codable, Equatable {
    public let address: String
    
    public init(_ address: String) throws {
        guard address.hasPrefix("0x") else {
            throw AddressError.invalidFormat("Address must start with 0x")
        }
        self.address = address
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let addressString = try container.decode(String.self)
        try self.init(addressString)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(address)
    }
}

public enum AddressError: Error {
    case invalidFormat(String)
}

public struct EntryPoint {
    public let address: String
    public let version: String
    public let chain: Chain
    
    public init(address: String, version: String, chain: Chain) {
        self.address = address
        self.version = version
        self.chain = chain
    }
}

public struct Policy: Codable {
    public let policyId: String
    
    public init(policyId: String) {
        self.policyId = policyId
    }
}

public struct PaymasterDataParams: Encodable {
    public let userOperation: UserOperationRequest
    public let entryPoint: String
    public let chainId: String
    public let policy: Policy?
    
    public init(userOperation: UserOperationRequest, entryPoint: String, chainId: String, policy: Policy? = nil) {
        self.userOperation = userOperation
        self.entryPoint = entryPoint
        self.chainId = chainId
        self.policy = policy
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(userOperation)
        try container.encode(entryPoint)
        try container.encode(chainId)
        try container.encode(policy)
    }
}

public struct SendUserOperationResult {
    public let hash: String
    public let request: UserOperationRequest
}

public struct UserOperationOverrides {
    public let callGasLimit: BigUInt?
    public let maxFeePerGas: BigUInt?
    public let maxPriorityFeePerGas: BigUInt?
    public let preVerificationGas: BigUInt?
    public let verificationGasLimit: BigUInt?
    public let paymasterVerificationGasLimit: BigUInt?
    public let paymasterAndData: String?
    
    public init(callGasLimit: BigUInt? = nil, maxFeePerGas: BigUInt? = nil, maxPriorityFeePerGas: BigUInt? = nil, preVerificationGas: BigUInt? = nil, verificationGasLimit: BigUInt? = nil, paymasterVerificationGasLimit: BigUInt? = nil, paymasterAndData: String? = nil) {
        self.callGasLimit = callGasLimit
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.preVerificationGas = preVerificationGas
        self.verificationGasLimit = verificationGasLimit
        self.paymasterVerificationGasLimit = paymasterVerificationGasLimit
        self.paymasterAndData = paymasterAndData
    }
}

public struct UserOperationCallData: Equatable  {
    /// the target of the call
    public let target: EthereumAddress
    /// the data passed to the target
    public let data: Data
    /// the amount of native token to send to the target (default: 0)
    public let value: BigUInt?
    
    public init(target: EthereumAddress, data: Data, value: BigUInt? = nil) {
        self.target = target
        self.data = data
        self.value = value
    }
}

/// Represents the request as it needs to be formatted for RPC requests
public struct UserOperationRequest: Equatable, Encodable {
    /// The origin of the request
    public let sender: String
    /// Nonce of the transaction, returned from the entrypoint for this Address
    public let nonce: String
    /// The initCode for creating the sender if it does not exist yet, otherwise "0x"
    public let initCode: String?
    /// The callData passed to the target
    public let callData: String
    
    /// Value used by inner account execution
    public let callGasLimit: String?
    /// Actual gas used by the validation of this UserOperation
    public let verificationGasLimit: String?
    /// Gas overhead of this UserOperation
    public let preVerificationGas: String?
    /// Maximum fee per gas (similar to EIP-1559 max_fee_per_gas)
    public let maxFeePerGas: String?
    /// Maximum priority fee per gas (similar to EIP-1559 max_priority_fee_per_gas)
    public let maxPriorityFeePerGas: String?
    /// Data passed into the account along with the nonce during the verification step
    public let signature: String
    
    // v6 fields
    /// Address of paymaster sponsoring the transaction, followed by extra data to send to the paymaster ("0x" for self-sponsored transaction)
    public let paymasterAndData: String?
    
    // v7 fields
    /// address of paymaster contract, (or empty, if account pays for itself)
    public let paymaster: String?
    /// the amount of gas to allocate for the paymaster validation code
    public let paymasterVerificationGasLimit: String?
    /// the amount of gas to allocate for the paymaster post-operation code
    public let paymasterPostOpGasLimit: String?
    /// data for paymaster (only if paymaster exists)
    public let paymasterData: String?
    /// EIP-7702 authorization tuple for account delegation (optional)
    public let eip7702Auth: Eip7702Auth?
    /// account factory, only for new accounts
    public let factory: String?
    /// data for account factory (only if account factory exists)
    public let factoryData: String?
    
    public init(sender: String, nonce: String, initCode: String? = nil, callData: String, callGasLimit: String? = nil, verificationGasLimit: String? = nil, preVerificationGas: String? = nil, maxFeePerGas: String? = nil, maxPriorityFeePerGas: String? = nil, signature: String, paymasterAndData: String? = nil, paymaster: String? = nil, paymasterVerificationGasLimit: String? = nil, paymasterPostOpGasLimit: String? = nil, paymasterData: String? = nil, eip7702Auth: Eip7702Auth? = nil, factory: String? = nil, factoryData: String? = nil) {
        self.sender = sender
        self.nonce = nonce
        self.initCode = initCode
        self.callData = callData
        self.callGasLimit = callGasLimit
        self.verificationGasLimit = verificationGasLimit
        self.preVerificationGas = preVerificationGas
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.signature = signature
        self.paymasterAndData = paymasterAndData
        self.paymaster = paymaster
        self.paymasterVerificationGasLimit = paymasterVerificationGasLimit
        self.paymasterPostOpGasLimit = paymasterPostOpGasLimit
        self.paymasterData = paymasterData
        self.eip7702Auth = eip7702Auth
        self.factory = factory
        self.factoryData = factoryData
    }
}

/// Based on @account-abstraction/common
/// This is used for building requests
public struct UserOperationStruct: Equatable {
    /// The origin of the request
    public var sender: String
    /// Nonce of the transaction, returned from the entrypoint for this Address
    public var nonce: BigUInt
    /// The initCode for creating the sender if it does not exist yet, otherwise "0x"
    public var initCode: String?
    /// The callData passed to the target
    public var callData: String
    /// Value used by inner account execution
    public var callGasLimit: BigUInt?
    /// Actual gas used by the validation of this UserOperation
    public var verificationGasLimit: BigUInt?
    /// Gas overhead of this UserOperation
    public var preVerificationGas: BigUInt?
    /// Maximum fee per gas (similar to EIP-1559 max_fee_per_gas)
    public var maxFeePerGas: BigUInt?
    /// Maximum priority fee per gas (similar to EIP-1559 max_priority_fee_per_gas)
    public var maxPriorityFeePerGas: BigUInt?
    /// Data passed into the account along with the nonce during the verification step
    public var signature: Data
    
    // v6 fields
    /// Address of paymaster sponsoring the transaction, followed by extra data to send to the paymaster ("0x" for self-sponsored transaction)
    public var paymasterAndData: String?
    
    // v7 fields
    /// address of paymaster contract, (or empty, if account pays for itself)
    public var paymaster: String?
    /// the amount of gas to allocate for the paymaster validation code
    public var paymasterVerificationGasLimit: BigUInt?
    /// the amount of gas to allocate for the paymaster post-operation code
    public var paymasterPostOpGasLimit: BigUInt?
    /// data for paymaster (only if paymaster exists)
    public var paymasterData: String?
    /// account factory, only for new accounts
    public var factory: String?
    /// data for account factory (only if account factory exists)
    public var factoryData: String?
    /// EIP-7702 authorization tuple for account delegation (optional)
    public var eip7702Auth: Eip7702Auth?
    
    public init(sender: String, nonce: BigUInt, initCode: String? = nil, callData: String, callGasLimit: BigUInt? = nil, verificationGasLimit: BigUInt? = nil, preVerificationGas: BigUInt? = nil, maxFeePerGas: BigUInt? = nil, maxPriorityFeePerGas: BigUInt? = nil, signature: Data, paymasterAndData: String? = nil, paymaster: String? = nil, paymasterVerificationGasLimit: BigUInt? = nil, paymasterPostOpGasLimit: BigUInt? = nil, paymasterData: String? = nil, factory: String? = nil, factoryData: String? = nil, eip7702Auth: Eip7702Auth? = nil) {
        self.sender = sender
        self.nonce = nonce
        self.initCode = initCode
        self.callData = callData
        self.callGasLimit = callGasLimit
        self.verificationGasLimit = verificationGasLimit
        self.preVerificationGas = preVerificationGas
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.signature = signature
        self.paymasterAndData = paymasterAndData
        self.paymaster = paymaster
        self.paymasterVerificationGasLimit = paymasterVerificationGasLimit
        self.paymasterPostOpGasLimit = paymasterPostOpGasLimit
        self.paymasterData = paymasterData
        self.factory = factory
        self.factoryData = factoryData
        self.eip7702Auth = eip7702Auth
    }
    
    public static func == (lhs: UserOperationStruct, rhs: UserOperationStruct) -> Bool {
        return lhs.sender == rhs.sender &&
               lhs.nonce == rhs.nonce &&
               lhs.initCode == rhs.initCode &&
               lhs.callData == rhs.callData &&
               lhs.callGasLimit == rhs.callGasLimit &&
               lhs.verificationGasLimit == rhs.verificationGasLimit &&
               lhs.preVerificationGas == rhs.preVerificationGas &&
               lhs.maxFeePerGas == rhs.maxFeePerGas &&
               lhs.maxPriorityFeePerGas == rhs.maxPriorityFeePerGas &&
               lhs.signature == rhs.signature &&
               lhs.paymasterAndData == rhs.paymasterAndData &&
               lhs.paymaster == rhs.paymaster &&
               lhs.paymasterVerificationGasLimit == rhs.paymasterVerificationGasLimit &&
               lhs.paymasterPostOpGasLimit == rhs.paymasterPostOpGasLimit &&
               lhs.paymasterData == rhs.paymasterData &&
               lhs.factory == rhs.factory &&
               lhs.factoryData == rhs.factoryData &&
               lhs.eip7702Auth?.chainId == rhs.eip7702Auth?.chainId &&
               lhs.eip7702Auth?.nonce == rhs.eip7702Auth?.nonce &&
               lhs.eip7702Auth?.address == rhs.eip7702Auth?.address &&
               lhs.eip7702Auth?.r == rhs.eip7702Auth?.r &&
               lhs.eip7702Auth?.s == rhs.eip7702Auth?.s &&
               lhs.eip7702Auth?.yParity == rhs.eip7702Auth?.yParity
    }
}

public struct UserOperationReceipt: Equatable, Codable {
    enum CodingKeys: String, CodingKey {
        case userOpHash
        case entryPoint
        case sender
        case nonce
        case paymaster
        case actualGasCost
        case actualGasUsed
        case success
        case reason
    }
    
    /// The request hash of the UserOperation.
    public let userOpHash: String
    /// The entry point address used for the UserOperation.
    public let entryPoint: String
    /// The account initiating the UserOperation.
    public let sender: String
    /// The nonce used in the UserOperation.
    public let nonce: String
    /// The paymaster used for this UserOperation (or empty).
    public let paymaster: String?
    /// The actual amount paid (by account or paymaster) for this UserOperation.
    public let actualGasCost: String
    /// The total gas used by this UserOperation (including preVerification, creation, validation, and execution).
    public let actualGasUsed: String
    /// Indicates whether the execution completed without reverting.
    public let success: Bool
    /// In case of revert, this is the revert reason.
    public let reason: String?
    
    public init(userOpHash: String, entryPoint: String, sender: String, nonce: String, paymaster: String?, actualGasCost: String, actualGasUsed: String, success: Bool, reason: String?) {
        self.userOpHash = userOpHash
        self.entryPoint = entryPoint
        self.sender = sender
        self.nonce = nonce
        self.paymaster = paymaster
        self.actualGasCost = actualGasCost
        self.actualGasUsed = actualGasUsed
        self.success = success
        self.reason = reason
    }
}
