//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import BigInt
import web3
import AASwift

let alchemyFeeEstimator: ClientMiddlewareFn = { client, account, operation, overrides in
    var updatedOperation = operation
    if overrides.maxFeePerGas != nil && overrides.maxPriorityFeePerGas != nil {
        updatedOperation.maxFeePerGas = overrides.maxFeePerGas
        updatedOperation.maxPriorityFeePerGas = overrides.maxPriorityFeePerGas
    } else {
        let block = try await client.eth_getBlockFeeInfoByNumber(EthereumBlock.Latest)
        let baseFeePerGas = block.baseFeePerGas ?? BigUInt(0)
        let maxPriorityFeePerGasEstimate =
            // it's a fair assumption that if someone is using this Alchemy Middleware, then they are using Alchemy RPC
            try await (client as! AlchemyClient).maxPriorityFeePerGas()

        let maxPriorityFeePerGas = overrides.maxPriorityFeePerGas ?? maxPriorityFeePerGasEstimate
        updatedOperation.maxPriorityFeePerGas = maxPriorityFeePerGas
        updatedOperation.maxFeePerGas = baseFeePerGas + maxPriorityFeePerGas
    }
        
    return updatedOperation
}
