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
        withGasEstimator(gasEstimator: { _, _, uoStruct, overrides in
            var updatedUO = uoStruct
            updatedUO.callGasLimit = overrides.callGasLimit ?? BigUInt(0)
            updatedUO.preVerificationGas = overrides.preVerificationGas ?? BigUInt(0)
            updatedUO.verificationGasLimit = overrides.verificationGasLimit ?? BigUInt(0)
            return updatedUO
        })
        
        withDummyPaymasterMiddleware(
            middleware: { _, _, uoStruct, _ in
                var updatedUO = uoStruct
                updatedUO.paymasterAndData = "0xc03aac639bb21233e0139381970328db8bceeb67fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c"
                return updatedUO
            }
        )
        
        withPaymasterMiddleware(
            middleware: { client, _, uoStruct, overrides in
                var updatedUO = uoStruct
                updatedUO.callGasLimit = overrides.callGasLimit
                updatedUO.preVerificationGas = overrides.preVerificationGas
                updatedUO.verificationGasLimit = overrides.verificationGasLimit
                updatedUO.paymasterAndData = overrides.paymasterAndData ?? "0x"
                
                if overrides.callGasLimit == nil ||
                    overrides.preVerificationGas == nil ||
                    overrides.verificationGasLimit == nil ||
                    overrides.paymasterAndData == nil {
                    
                    let request = uoStruct.toUserOperationRequest()
                    if let coinbaseClient = client as? CoinbaseClient {
                        let result = try await coinbaseClient.sponsorUserOperation(
                            userOp: request,
                            entryPoint: self.getEntryPoint().address
                        )
                        
                        updatedUO.callGasLimit = result.callGasLimit
                        updatedUO.preVerificationGas = result.preVerificationGas
                        updatedUO.verificationGasLimit = result.verificationGasLimit
                        updatedUO.paymasterAndData = result.paymasterAndData ?? "0x"
                    }
                }
                
                return updatedUO
            }
        )
        
        return withMiddlewareRpcClient(
            rpcClient: try CoinbaseProvider.createRpcClient(
                config: ProviderConfig(chain: chain, connectionConfig: connectionConfig)
            )
        ) as! Self
    }
}
