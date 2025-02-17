//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import web3
import AASwift

public enum LightAccountVersion: String {
    /// This version does not support 1271 signature validation
    @available(*, deprecated, message: "This version does not support 1271 signature validation")
    case v1_0_1 = "v1.0.1"
    
    /// This version has a known issue with 1271 validation, it's recommended to use v1.1.0
    @available(*, deprecated, message: "This version has a known issue with 1271 validation, it's recommended to use v1.1.0")
    case v1_0_2 = "v1.0.2"
    
    /// Recommended version
    case v1_1_0 = "v1.1.0"
}

/// Defines properties for each LightAccount version.
let lightAccountVersions: [LightAccountVersion: (factoryAddress: EthereumAddress, implAddress: EthereumAddress)] = [
    .v1_0_1: (
        factoryAddress: EthereumAddress("0x000000893A26168158fbeaDD9335Be5bC96592E2"),
        implAddress: EthereumAddress("0xc1b2fc4197c9187853243e6e4eb5a4af8879a1c0")
    ),
    .v1_0_2: (
        factoryAddress: EthereumAddress("0x00000055C0b4fA41dde26A74435ff03692292FBD"),
        implAddress: EthereumAddress("0x5467b1947F47d0646704EB801E075e72aeAe8113")
    ),
    .v1_1_0: (
        factoryAddress: EthereumAddress("0x00004EC70002a32400f8ae005A26081065620D20"),
        implAddress: EthereumAddress("0xae8c656ad28F2B59a196AB61815C16A0AE1c3cba")
    )
]

extension Chain {
    public func getDefaultLightAccountFactoryAddress(version: LightAccountVersion = LightAccountVersion.v1_1_0) throws -> EthereumAddress {
        switch self.id {
        case Chain.MainNet.id,
             Chain.Sepolia.id,
             Chain.Polygon.id,
             Chain.Optimism.id,
             Chain.OptimismGoerli.id,
             Chain.Arbitrum.id,
             Chain.ArbitrumGoerli.id,
             Chain.Base.id,
             Chain.BaseGoerli.id,
             Chain.BaseSepolia.id: lightAccountVersions[version]!.factoryAddress

        default: throw ProviderError.noFactoryAddress("no default light account factory contract exists for \(name)")
        }
    }
}
