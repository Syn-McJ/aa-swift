//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import AASwift
import web3

public func createCoinbaseClient(
    url: String,
    chain: Chain,
    headers: [String: String] = [:]
) throws -> CoinbaseClient {
    guard let validUrl = URL(string: url) else {
        throw ProviderError.invalidUrl("Invalid URL format: \(url)")
    }
    
    return CoinbaseRpcClient(
        url: validUrl,
        network: EthereumNetwork.custom(chain.id.description),
        headers: headers
    )
}
