//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift
import Foundation
import web3
import BigInt

public func createAlchemyClient(
    url: String,
    chain: Chain,
    headers: [String: String] = [:]
) throws -> AlchemyClient {
    guard let validUrl = URL(string: url) else {
        throw ProviderError.invalidUrl("Invalid URL format: \(url)")
    }
    
    return AlchemyRpcClient(
        url: validUrl,
        network: EthereumNetwork.custom(chain.id.description),
        headers: headers
    )
}
