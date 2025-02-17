//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift
import BigInt

public protocol AlchemyClient: Erc4337Client {
    func maxPriorityFeePerGas() async throws -> BigUInt
    func requestPaymasterAndData(params: PaymasterAndDataParams) async throws -> PaymasterAndData
    func requestGasAndPaymasterAndData(params: PaymasterAndDataParams) async throws -> AlchemyGasAndPaymasterAndData
}
