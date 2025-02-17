//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift
import web3

class CoinbaseRpcClient: Erc4337RpcClient, CoinbaseClient {
    public func getPaymasterData(params: PaymasterDataParams) async throws -> PaymasterAndData {
        do {
            let data = try await networkProvider.send(method: "pm_getPaymasterStubData", params: params, receive: PaymasterAndData.self)
            if let result = data as? PaymasterAndData {
                return result
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }
    
    public func sponsorUserOperation(userOp: UserOperationRequest, entryPoint: String) async throws -> SponsoredUserOperation {
        do {
            let params = SponsorUserOpParams(userOperation: userOp, entryPoint: entryPoint)
            let data = try await networkProvider.send(method: "pm_sponsorUserOperation", params: params, receive: SponsoredUserOperation.self)
            if let result = data as? SponsoredUserOperation {
                return result
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }
}
