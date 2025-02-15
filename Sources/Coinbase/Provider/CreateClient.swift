import Foundation
import AASwift
import web3

public func createCoinbaseClient(
    url: String,
    chain: Chain,
    headers: [String: String] = [:]
) -> CoinbaseClient {
    return CoinbaseRpcClient(url: URL(string: url)!, network: EthereumNetwork.custom(String(describing: chain.id)), headers: headers)
}
