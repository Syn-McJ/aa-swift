//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import web3
import Foundation
import BigInt

public func failureHandler(_ error: Error, methodName: String) -> BundlerClientError {
    let ethereumError: EthereumClientError
    
    if case var .executionError(result) = error as? JSONRPCError {
        var error = result.error
        error.data = methodName
        ethereumError = EthereumClientError.executionError(error)
    } else if let error = error as? EthereumClientError {
        ethereumError = error
    } else {
        ethereumError = EthereumClientError.unexpectedReturnValue
    }
    
    return BundlerClientError(methodName: methodName, underlyingError: ethereumError)
}

struct UserOpCallParams: Encodable {
    let request: UserOperationRequest
    let entryPoint: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(request)
        try container.encode(entryPoint)
    }
}

fileprivate struct GetBlockByNumberCallParams: Encodable {
    let block: EthereumBlock
    let fullTransactions: Bool

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(block.stringValue)
        try container.encode(fullTransactions)
    }
}

open class BundlerRpcClient: BaseEthereumClient, BundlerClient {
    let networkQueue: OperationQueue

    public init(url: URL, network: EthereumNetwork, headers: [String: String] = [:]) {
        let networkQueue = OperationQueue()
        networkQueue.name = "Erc4337RpcClient.networkQueue"
        networkQueue.maxConcurrentOperationCount = 4
        self.networkQueue = networkQueue
        let configuration = URLSession.shared.configuration
        configuration.httpAdditionalHeaders = headers
        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: networkQueue)
        
        super.init(networkProvider: HttpNetworkProvider(session: session, url: url), url: url, logger: nil, network: network)
    }
    
    public func estimateUserOperationGas(request: UserOperationRequest, entryPoint: String) async throws -> EstimateUserOperationGasResponse {
        let methodName = "eth_estimateUserOperationGas"
        
        do {
            let data = try await networkProvider.send(method: methodName, params: UserOpCallParams(request: request, entryPoint: entryPoint), receive: EstimateUserOperationGasResponse.self)
            if let result = data as? EstimateUserOperationGasResponse {
                return result
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error, methodName: methodName)
        }
    }
    
    public func sendUserOperation(request: UserOperationRequest, entryPoint: String) async throws -> String {
        let methodName = "eth_sendUserOperation"
        
        do {
            let data = try await networkProvider.send(method: methodName, params: UserOpCallParams(request: request, entryPoint: entryPoint), receive: String.self)
            if let result = data as? String {
                return result
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error, methodName: methodName)
        }
    }
    
    public func getUserOperationReceipt(hash: String) async throws -> UserOperationReceipt {
        let methodName = "eth_getUserOperationReceipt"
        
        do {
            let data = try await networkProvider.send(method: methodName, params: [hash], receive: UserOperationReceipt.self)
            if let result = data as? UserOperationReceipt {
                return result
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error, methodName: methodName)
        }
    }
    
    open func eth_maxPriorityFeePerGas() async throws -> BigUInt {
        let methodName = "eth_maxPriorityFeePerGas"
        
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
    
    public func estimateFeesPerGas(chain: Chain) async throws -> FeeValuesEIP1559 {
        let baseFeeMultiplier = chain.baseFeeMultiplier ?? 1.2
        
        guard baseFeeMultiplier >= 1 else {
            throw NSError(domain: "InvalidArguments", code: 0, userInfo: [NSLocalizedDescriptionKey: "`baseFeeMultiplier` must be greater than 1."])
        }

        let decimals = abs(Decimal(baseFeeMultiplier).exponent)
        let denominator = pow(10.0, Double(decimals))

        let multiply: (BigUInt) -> BigUInt = { base in
            let multiplier = BigUInt(ceil(baseFeeMultiplier * denominator))
            return (base * multiplier) / BigUInt(denominator)
        }

        let block = try await eth_getBlockFeeInfoByNumber(EthereumBlock.Latest)
        let maxPriorityFeePerGas = chain.defaultPriorityFee != nil ? chain.defaultPriorityFee! : try await eth_maxPriorityFeePerGas()
        let baseFeePerGas = multiply(block.baseFeePerGas ?? BigUInt(0))
        let maxFeePerGas = baseFeePerGas + maxPriorityFeePerGas

        return FeeValuesEIP1559(
            gasPrice: baseFeePerGas,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas
        )
    }
    
    public func eth_getBlockFeeInfoByNumber(_ block: EthereumBlock) async throws -> EthereumBlockFeeInfo {
        let params = GetBlockByNumberCallParams(block: block, fullTransactions: false)
        let methodName = "eth_getBlockByNumber"

        do {
            let data = try await networkProvider.send(method: methodName, params: params, receive: EthereumBlockFeeInfo.self)
            if let blockData = data as? EthereumBlockFeeInfo {
                return blockData
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error, methodName: methodName)
        }
    }
}
