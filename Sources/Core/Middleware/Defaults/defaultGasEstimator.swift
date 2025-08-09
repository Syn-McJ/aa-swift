//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import BigInt
import web3

/// Default gas estimator middleware function for user operations.
/// This middleware estimates gas limits for user operations if they are not provided in overrides.
/// It checks if callGasLimit, verificationGasLimit, or preVerificationGas are missing,
/// and if so, makes a gas estimation request to the bundler.
/// 
/// For EntryPoint v0.7.0, it also handles paymasterVerificationGasLimit and sets
/// paymasterPostOpGasLimit to 0 if a paymaster is present.
public let defaultGasEstimator: ClientMiddlewareFn = { client, account, userOp, overrides in
    var updatedUserOp = userOp
    var estimates: EstimateUserOperationGasResponse? = nil
    let entryPoint = account.getEntryPoint()
    let is070 = entryPoint.version == "0.7.0"

    // Check if we need to estimate gas limits
    if (overrides.callGasLimit == nil ||
        overrides.verificationGasLimit == nil ||
        overrides.preVerificationGas == nil ||
        (is070 && overrides.paymasterVerificationGasLimit == nil)
    ) {
        let request = updatedUserOp.toUserOperationRequest()
        estimates = try await client.estimateUserOperationGas(
            request: request, 
            entryPoint: entryPoint.address
        )
    }

    // Set gas limits from overrides or estimates
    updatedUserOp.preVerificationGas = overrides.preVerificationGas ?? estimates?.preVerificationGas
    updatedUserOp.verificationGasLimit = overrides.verificationGasLimit ?? estimates?.verificationGasLimit
    updatedUserOp.callGasLimit = overrides.callGasLimit ?? estimates?.callGasLimit

    // Handle EntryPoint v0.7.0 specific fields
    if is070 {
        updatedUserOp.paymasterVerificationGasLimit = overrides.paymasterVerificationGasLimit ?? estimates?.paymasterVerificationGasLimit
        updatedUserOp.paymasterPostOpGasLimit = updatedUserOp.paymasterPostOpGasLimit ?? (updatedUserOp.paymaster == nil ? nil : BigUInt(0))
    }

    return updatedUserOp
}
