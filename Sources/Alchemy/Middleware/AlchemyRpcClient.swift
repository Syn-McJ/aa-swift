//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift
import Foundation
import BigInt
import web3

class AlchemyRpcClient: BundlerRpcClient, AlchemyClient {
    public func maxPriorityFeePerGas() async throws -> BigUInt {
        let methodName = "rundler_maxPriorityFeePerGas"
        
        do {
            let emptyParams: [Bool] = []
            let data = try await networkProvider.send(method: methodName, params: emptyParams, receive: String.self)
            
            if let feeHex = data as? String, let fee = BigUInt(hex: feeHex) {
                return fee
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error, methodName: methodName)
        }
    }
    
    public func requestPaymasterAndData(params: PaymasterAndDataParams) async throws -> PaymasterData {
        let methodName = "alchemy_requestPaymasterAndData"
        
        do {
            let data = try await networkProvider.send(method: methodName, params: [params], receive: PaymasterData.self)
            if let result = data as? PaymasterData {
                return result
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error, methodName: methodName)
        }
    }
    
    public func requestGasAndPaymasterAndData(params: PaymasterAndDataParams) async throws -> AlchemyGasAndPaymasterAndData {
        let methodName = "alchemy_requestGasAndPaymasterAndData"
        
        do {
            let data = try await networkProvider.send(method: methodName, params: [params], receive: AlchemyGasAndPaymasterAndData.self)
            if let result = data as? AlchemyGasAndPaymasterAndData {
                return result
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error, methodName: methodName)
        }
    }
    
    public func getPaymasterStubData(params: PaymasterDataParams) async throws -> PaymasterData {
        let methodName = "pm_getPaymasterStubData"
        
        do {
            let data = try await networkProvider.send(
                method: methodName,
                params: params,
                receive: PaymasterData.self
            )
            if let result = data as? PaymasterData {
                return result
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error, methodName: methodName)
        }
    }
}
