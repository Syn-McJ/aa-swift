//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import BigInt

public func concatHex(values: [String]) -> String {
    return values.map { $0.web3.noHexPrefix }.joined().web3.withHexPrefix
}

extension BigUInt {
    public var properHexString: String {
        if self == 0 {
            return "0x0"
        }
        return self.web3.hexStringNoLeadingZeroes
    }
}

extension UserOperationStruct {
    public func toUserOperationRequest() -> UserOperationRequest {
        return UserOperationRequest(
            sender: sender,
            nonce: nonce.properHexString,
            initCode: initCode,
            callData: callData,
            callGasLimit: (callGasLimit ?? BigUInt.zero).properHexString,
            verificationGasLimit: (verificationGasLimit ?? BigUInt.zero).properHexString,
            preVerificationGas: (preVerificationGas ?? BigUInt.zero).properHexString,
            maxFeePerGas: maxFeePerGas?.properHexString,
            maxPriorityFeePerGas: maxPriorityFeePerGas?.properHexString,
            signature: signature.web3.hexString,
            paymasterAndData: paymasterAndData,
            paymaster: paymaster,
            paymasterVerificationGasLimit: paymasterVerificationGasLimit?.properHexString,
            paymasterPostOpGasLimit: paymasterPostOpGasLimit?.properHexString,
            paymasterData: paymasterData,
            eip7702Auth: eip7702Auth,
            factory: factory,
            factoryData: factoryData
        )
    }
    
    /// Converts UserOperationStruct to UserOperationRequest with Kotlin-style defaults
    /// - nil gas fields become "0x0"
    /// - nil fee fields become "0x"
    public func toUserOperationRequestWithDefaults() -> UserOperationRequest {
        return UserOperationRequest(
            sender: sender,
            nonce: nonce.properHexString,
            initCode: initCode,
            callData: callData,
            callGasLimit: (callGasLimit ?? 0).properHexString,
            verificationGasLimit: (verificationGasLimit ?? 0).properHexString,
            preVerificationGas: (preVerificationGas ?? 0).properHexString,
            maxFeePerGas: maxFeePerGas?.properHexString ?? "0x",
            maxPriorityFeePerGas: maxPriorityFeePerGas?.properHexString ?? "0x",
            signature: signature.web3.hexString,
            paymasterAndData: paymasterAndData,
            paymaster: paymaster,
            paymasterVerificationGasLimit: (paymasterVerificationGasLimit ?? 0).properHexString,
            paymasterPostOpGasLimit: (paymasterPostOpGasLimit ?? 0).properHexString,
            paymasterData: paymasterData,
            eip7702Auth: eip7702Auth,
            factory: factory,
            factoryData: factoryData
        )
    }
}
