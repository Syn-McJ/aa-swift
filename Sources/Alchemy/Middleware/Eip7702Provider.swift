//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import AASwift
import BigInt
import web3

/// Extension to SmartAccountProvider to add ERC-7677 middleware support
extension SmartAccountProvider {
    /// Adds ERC-7677 middleware with the specified policy ID
    /// - Parameter policyId: The policy ID for paymaster data requests
    /// - Returns: The SmartAccountProvider with ERC-7677 middleware configured
    public func erc7677Middleware(policyId: String) -> SmartAccountProvider {
        // Configure dummy paymaster middleware
        withDummyPaymasterMiddleware(
            middleware: { client, account, uoStruct, overrides in
                var userOp = uoStruct
                
                // Reset values for fee estimation
                userOp.maxFeePerGas = BigUInt(0)
                userOp.maxPriorityFeePerGas = BigUInt(0)
                userOp.callGasLimit = BigUInt(0)
                userOp.verificationGasLimit = BigUInt(0)
                userOp.preVerificationGas = BigUInt(0)
                
                // Get entry point information
                // Account is now passed as parameter, no need to fetch from self
                
                let entryPoint = try account.getEntryPointAddress()
                let entryPointInfo = try? Defaults.getV7EntryPoint(chain: self.chain)
                let version = entryPointInfo?.version ?? "0.6.0"
                
                if version == "0.7.0" {
                    userOp.paymasterVerificationGasLimit = BigUInt(0)
                    userOp.paymasterPostOpGasLimit = BigUInt(0)
                }
                
                // Create paymaster data params
                let userOpRequest = userOp.toUserOperationRequest()
                let chainIdHex = String(format: "0x%x", self.chain.id)
                let policy = Policy(policyId: policyId)
                
                let params = PaymasterDataParams(
                    userOperation: userOpRequest,
                    entryPoint: entryPoint.asString(),
                    chainId: chainIdHex,
                    policy: policy
                )
                
                // Get paymaster stub data
                if let alchemyClient = client as? AlchemyRpcClient {
                    let result = try await alchemyClient.getPaymasterStubData(params: params)
                    
                    if version == "0.6.0" {
                        userOp.paymasterAndData = result.paymasterAndData
                        return userOp
                    }
                    
                    userOp.paymaster = result.paymaster
                    userOp.paymasterData = result.paymasterData
                    userOp.paymasterVerificationGasLimit = result.paymasterVerificationGasLimit
                    userOp.paymasterPostOpGasLimit = result.paymasterPostOpGasLimit
                    
                    return userOp
                }
                
                return userOp
            }
        )
        
        withUserOperationSigner(signer: { client, account, uoStruct, overrides in
            var userOp = uoStruct
            
            if let modularAccount = account as? ModularAccountV2, modularAccount.getMode() == .EIP7702 {
                // Use EIP-7702 signer
                userOp = try await default7702UserOpSigner(client: client, account: account, userOp: userOp, overrides: overrides)
            } else {
                // Use default signer
                userOp = try await defaultUserOpSigner(client: client, account: account, userOp: userOp, overrides: overrides)
            }
            
            return userOp
        })
        
        return self
    }
}
