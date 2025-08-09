//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import web3
import BigInt

public func createPublicBundlerClient(
    rpcUrl: String,
    chain: Chain,
    headers: [String: String] = [:]
) throws -> BundlerClient {
    guard let validUrl = URL(string: rpcUrl) else {
        throw ProviderError.invalidUrl("Invalid URL format: \(rpcUrl)")
    }
    
    return BundlerRpcClient(
        url: validUrl,
        network: EthereumNetwork.custom(chain.id.description),
        headers: headers
    )
}
