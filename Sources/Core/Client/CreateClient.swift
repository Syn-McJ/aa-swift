//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import web3
import BigInt

public func createPublicErc4337Client(
    rpcUrl: String,
    chain: Chain,
    headers: [String: String] = [:]
) throws -> Erc4337Client {
    guard let validUrl = URL(string: rpcUrl) else {
        throw ProviderError.invalidUrl("Invalid URL format: \(rpcUrl)")
    }
    
    return Erc4337RpcClient(
        url: validUrl,
        network: EthereumNetwork.custom(chain.id.description),
        headers: headers
    )
}
