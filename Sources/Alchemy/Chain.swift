//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift

public let SupportedChains = [
    Chain.Polygon.id: Chain.Polygon,
    Chain.MainNet.id: Chain.MainNet,
    Chain.Sepolia.id: Chain.Sepolia,
    Chain.ArbitrumGoerli.id: Chain.ArbitrumGoerli,
    Chain.ArbitrumSepolia.id: Chain.ArbitrumSepolia,
    Chain.Arbitrum.id: Chain.Arbitrum,
    Chain.Optimism.id: Chain.Optimism,
    Chain.OptimismGoerli.id: Chain.OptimismGoerli,
    Chain.OptimismSepolia.id: Chain.OptimismSepolia,
    Chain.Base.id: Chain.Base,
    Chain.BaseGoerli.id: Chain.BaseGoerli,
    Chain.BaseSepolia.id: Chain.BaseSepolia,
]

extension Chain {
    public var alchemyRpcHttpUrl: String? {
        switch self {
        case Chain.Polygon:
            return "https://polygon-mainnet.g.alchemy.com/v2"
        case Chain.MainNet:
            return "https://eth-mainnet.g.alchemy.com/v2"
        case Chain.Sepolia:
            return "https://eth-sepolia.g.alchemy.com/v2"
        case Chain.ArbitrumGoerli:
            return "https://arb-goerli.g.alchemy.com/v2"
        case Chain.Arbitrum:
            return "https://arb-mainnet.g.alchemy.com/v2"
        case Chain.Optimism:
            return "https://opt-mainnet.g.alchemy.com/v2"
        case Chain.OptimismGoerli:
            return "https://opt-goerli.g.alchemy.com/v2"
        case Chain.Base:
            return "https://base-mainnet.g.alchemy.com/v2"
        case Chain.BaseGoerli:
            return "https://base-goerli.g.alchemy.com/v2"
        case Chain.BaseSepolia:
            return "https://base-sepolia.g.alchemy.com/v2/"
        default:
            return nil
        }
    }

    public var alchemyRpcWebSocketUrl: String? {
        switch self {
        case Chain.Polygon:
            return "wss://polygon-mainnet.g.alchemy.com/v2"
        case Chain.MainNet:
            return "wss://eth-mainnet.g.alchemy.com/v2"
        case Chain.Sepolia:
            return "wss://eth-sepolia.g.alchemy.com/v2"
        case Chain.ArbitrumGoerli:
            return "wss://arb-goerli.g.alchemy.com/v2"
        case Chain.Arbitrum:
            return "wss://arb-mainnet.g.alchemy.com/v2"
        case Chain.Optimism:
            return "wss://opt-mainnet.g.alchemy.com/v2"
        case Chain.OptimismGoerli:
            return "wss://opt-goerli.g.alchemy.com/v2"
        case Chain.Base:
            return "wss://base-mainnet.g.alchemy.com/v2"
        case Chain.BaseGoerli:
            return "wss://base-goerli.g.alchemy.com/v2"
        case Chain.BaseSepolia:
            return "wss://base-sepolia.g.alchemy.com/v2"
        default:
            return nil
        }
    }
}
