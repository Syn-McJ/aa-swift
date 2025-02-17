//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

public struct ProviderConfig {
    public let chain: Chain
    public let connectionConfig: ConnectionConfig
    public let opts: SmartAccountProviderOpts?
    
    public init(chain: Chain, connectionConfig: ConnectionConfig, opts: SmartAccountProviderOpts? = nil) {
        self.chain = chain
        self.connectionConfig = connectionConfig
        self.opts = opts
    }
}
