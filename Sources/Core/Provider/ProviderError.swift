//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

public enum ProviderError: Error {
    case unsupportedChain(String)
    case rpcUrlNotFound(String)
    case noFactoryAddress(String)
    case invalidUrl(String)
}
