//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import web3

public enum DefaultsError: Error {
    case noDefaultEntryPoint(String)
    case noDefaultSimpleAccountFactory(String)
}

extension Chain {
    /**
     * Utility method returning the entry point contract address given a Chain object
     *
     * - Parameter chain: a Chain object
     * - Returns: an Address for the given chain
     * - Throws: if the chain doesn't have an address currently deployed
     */
    public func getDefaultEntryPointAddress() throws -> EthereumAddress {
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
             Chain.BaseSepolia.id:
            return EthereumAddress("0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789")
        default:
            throw DefaultsError.noDefaultEntryPoint("no default entry point contract exists for \(name)")
        }
    }

    /**
     * Utility method returning the default simple account factory address given a Chain object
     *
     * - Parameter chain: a Chain object
     * - Returns: an Address for the given chain
     * - Throws: if the chain doesn't have an address currently deployed
     */
    public func getDefaultSimpleAccountFactoryAddress() throws -> EthereumAddress {
        switch self.id {
        case Chain.MainNet.id,
             Chain.Polygon.id,
             Chain.Optimism.id,
             Chain.Arbitrum.id,
             Chain.Base.id,
             Chain.BaseGoerli.id,
             Chain.BaseSepolia.id:
            return EthereumAddress("0x15Ba39375ee2Ab563E8873C8390be6f2E2F50232")
        case Chain.Sepolia.id,
             Chain.OptimismGoerli.id,
             Chain.ArbitrumGoerli.id:
            return EthereumAddress("0x9406Cc6185a346906296840746125a0E44976454")
        default:
            throw DefaultsError.noDefaultSimpleAccountFactory("no default simple account factory contract exists for \(name)")
        }
    }
}
