//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift

let SupportedChains: [Int64: Chain] = [
    Chain.Base.id: Chain.Base,
    Chain.BaseSepolia.id: Chain.BaseSepolia
]

extension Chain {
    var coinbasePaymasterAndBundlerUrl: String? {
        switch self {
        case Chain.Base:
            return "https://api.developer.coinbase.com/rpc/v1/base"
        case Chain.BaseSepolia:
            return "https://api.developer.coinbase.com/rpc/v1/base-sepolia"
        default:
            return nil
        }
    }
}
