//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import BigInt
import AASwift

extension SmartAccountProvider {
    @discardableResult
    public func withCoinbaseGasManager(connectionConfig: ConnectionConfig) throws -> Self {
        withGasEstimator(gasEstimator: { _, uoStruct, overrides in
            uoStruct.callGasLimit = overrides.callGasLimit ?? BigUInt(0)
            uoStruct.preVerificationGas = overrides.preVerificationGas ?? BigUInt(0)
            uoStruct.verificationGasLimit = overrides.verificationGasLimit ?? BigUInt(0)
            return uoStruct
        })
        
        withPaymasterMiddleware(
            dummyPaymasterDataMiddleware: { _, uoStruct, _ in
                uoStruct.paymasterAndData = "0xc03aac639bb21233e0139381970328db8bceeb67fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c"
                return uoStruct
            },
            paymasterDataMiddleware: { client, uoStruct, overrides in
                uoStruct.callGasLimit = overrides.callGasLimit
                uoStruct.preVerificationGas = overrides.preVerificationGas
                uoStruct.verificationGasLimit = overrides.verificationGasLimit
                uoStruct.paymasterAndData = overrides.paymasterAndData ?? "0x"
                
                if overrides.callGasLimit == nil ||
                    overrides.preVerificationGas == nil ||
                    overrides.verificationGasLimit == nil ||
                    overrides.paymasterAndData == nil {
                    
                    let request = uoStruct.toUserOperationRequest()
                    if let coinbaseClient = client as? CoinbaseClient {
                        let result = try await coinbaseClient.sponsorUserOperation(
                            userOp: request,
                            entryPoint: try self.getEntryPointAddress().asString()
                        )
                        
                        uoStruct.callGasLimit = result.callGasLimit
                        uoStruct.preVerificationGas = result.preVerificationGas
                        uoStruct.verificationGasLimit = result.verificationGasLimit
                        uoStruct.paymasterAndData = result.paymasterAndData
                    }
                }
                
                return uoStruct
            }
        )
        
        return withMiddlewareRpcClient(
            rpcClient: try CoinbaseProvider.createRpcClient(
                config: ProviderConfig(chain: chain, connectionConfig: connectionConfig)
            )
        ) as! Self
    }
}
