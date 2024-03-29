//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import web3
import AASwift

extension Chain {
    public func getDefaultLightAccountFactoryAddress() throws -> EthereumAddress {
        switch self.id {
        case Chain.MainNet.id,
             Chain.Sepolia.id,
             Chain.Goerli.id,
             Chain.Polygon.id,
             Chain.PolygonMumbai.id,
             Chain.Optimism.id,
             Chain.OptimismGoerli.id,
             Chain.Arbitrum.id,
             Chain.ArbitrumGoerli.id,
             Chain.Base.id,
             Chain.BaseGoerli.id: EthereumAddress("0x000000893A26168158fbeaDD9335Be5bC96592E2")

        default: throw AlchemyError.noFactoryAddress("no default light account factory contract exists for \(name)")
        }
    }
}
