//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift
import Foundation
import BigInt
import web3

class AlchemyRpcClient: Erc4337RpcClient, AlchemyClient {
    public func maxPriorityFeePerGas() async throws -> BigUInt {
        do {
            let emptyParams: [Bool] = []
            let data = try await networkProvider.send(method: "rundler_maxPriorityFeePerGas", params: emptyParams, receive: String.self)
            
            if let feeHex = data as? String, let fee = BigUInt(hex: feeHex) {
                return fee
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }
    
    public func requestPaymasterAndData(params: PaymasterAndDataParams) async throws -> PaymasterAndData {
        do {
            let data = try await networkProvider.send(method: "alchemy_requestPaymasterAndData", params: [params], receive: PaymasterAndData.self)
            if let result = data as? PaymasterAndData {
                return result
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }
    
    public func requestGasAndPaymasterAndData(params: PaymasterAndDataParams) async throws -> AlchemyGasAndPaymasterAndData {
        do {
            let data = try await networkProvider.send(method: "alchemy_requestGasAndPaymasterAndData", params: [params], receive: AlchemyGasAndPaymasterAndData.self)
            if let result = data as? AlchemyGasAndPaymasterAndData {
                return result
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }
}
