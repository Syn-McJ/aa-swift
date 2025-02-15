//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

public struct ConnectionConfig {
    public let apiKey: String?
    public let jwt: String?
    public let rpcUrl: String?
    
    public init(apiKey: String?, jwt: String?, rpcUrl: String? = nil) {
        self.apiKey = apiKey
        self.jwt = jwt
        self.rpcUrl = rpcUrl
    }
}
