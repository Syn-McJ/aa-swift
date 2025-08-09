//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift
import web3

class CoinbaseRpcClient: BundlerRpcClient, CoinbaseClient {
    public func getPaymasterData(params: AASwift.PaymasterDataParams) async throws -> PaymasterData {
        let methodName = "pm_getPaymasterStubData"
        
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
    
    // Implement Erc7677Client protocol
    public func getPaymasterStubData(params: AASwift.PaymasterDataParams) async throws -> PaymasterData {
        return try await getPaymasterData(params: params)
    }
    
    public func sponsorUserOperation(userOp: UserOperationRequest, entryPoint: String) async throws -> SponsoredUserOperation {
        let methodName = "pm_sponsorUserOperation"
        
        do {
            let params = SponsorUserOpParams(userOperation: userOp, entryPoint: entryPoint)
            let data = try await networkProvider.send(method: methodName, params: params, receive: SponsoredUserOperation.self)
            if let result = data as? SponsoredUserOperation {
                return result
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error, methodName: methodName)
        }
    }
}
