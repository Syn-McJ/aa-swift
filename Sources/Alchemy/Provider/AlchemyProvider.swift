//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift
import web3
import BigInt
import Foundation

public class AlchemyProvider: SmartAccountProvider {
    static private var rpcUrl: String = ""

    static internal func createRpcClient(config: ProviderConfig) throws -> Erc4337Client {
        guard let chain = SupportedChains[config.chain.id] else {
            throw ProviderError.unsupportedChain("Unsupported chain id: \(config.chain.id)")
        }

        guard let rpcUrl = config.connectionConfig.rpcUrl ?? (chain.alchemyRpcHttpUrl.map {
            let apiKey = config.connectionConfig.apiKey ?? ""
            return apiKey.isEmpty ? $0 : "\($0)/\(apiKey)"
        }) else {
            throw ProviderError.rpcUrlNotFound("No rpcUrl found for chain \(config.chain.id)")
        }

        let headers = config.connectionConfig.jwt.map {
            ["Authorization": "Bearer \($0)"]
        } ?? [:]
        let rpcClient = try createAlchemyClient(url: rpcUrl, chain: config.chain, headers: headers)
        self.rpcUrl = rpcUrl

        return rpcClient
    }

    public init(entryPointAddress: EthereumAddress?, config: ProviderConfig) throws {
        let rpcClient = try AlchemyProvider.createRpcClient(config: config)
        try super.init(client: rpcClient, rpcUrl: nil, entryPointAddress: entryPointAddress, chain: config.chain, opts: config.opts)
        withGasEstimator(gasEstimator: alchemyFeeEstimator)
    }
}
