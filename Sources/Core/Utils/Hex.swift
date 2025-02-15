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
            callGasLimit: (callGasLimit ?? BigUInt(0)).properHexString,
            verificationGasLimit: (verificationGasLimit ?? BigUInt(0)).properHexString,
            preVerificationGas: (preVerificationGas ?? BigUInt(0)).properHexString,
            maxFeePerGas: maxFeePerGas?.properHexString ?? "0x0",
            maxPriorityFeePerGas: maxPriorityFeePerGas?.properHexString ?? "0x0",
            paymasterAndData: paymasterAndData,
            signature: signature.web3.hexString
        )
    }
}
