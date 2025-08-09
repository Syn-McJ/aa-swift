//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation
import BigInt
import AASwift

public struct AlchemyGasManagerConfig {
    public let policyId: String
    public let connectionConfig: ConnectionConfig
    
    public init(policyId: String, connectionConfig: ConnectionConfig) {
        self.policyId = policyId
        self.connectionConfig = connectionConfig
    }
}

public struct AlchemyGasEstimationOptions {
    public let disableGasEstimation: Bool
    public let fallbackGasEstimator: ClientMiddlewareFn?
    public let fallbackFeeDataGetter: ClientMiddlewareFn?
    
    public init(
        disableGasEstimation: Bool = false,
        fallbackGasEstimator: ClientMiddlewareFn? = nil,
        fallbackFeeDataGetter: ClientMiddlewareFn? = nil
    ) {
        self.disableGasEstimation = disableGasEstimation
        self.fallbackGasEstimator = fallbackGasEstimator
        self.fallbackFeeDataGetter = fallbackFeeDataGetter
    }
}

extension SmartAccountProvider {
    /// This middleware wraps the Alchemy Gas Manager APIs to provide more flexible UserOperation gas sponsorship.
    ///
    /// If `estimateGas` is true, it will use `alchemy_requestGasAndPaymasterAndData` to get all of the gas estimates + paymaster data
    /// in one RPC call.
    ///
    /// Otherwise, it will use `alchemy_requestPaymasterAndData` to get only paymaster data, allowing you
    /// to customize the gas and fee estimation middleware.
    ///
    /// @param self - the smart account provider to override to use the alchemy gas manager
    /// @param config - the alchemy gas manager configuration
    /// @param gasEstimationOptions - options to customize gas estimation middleware
    /// @returns the provider augmented to use the alchemy gas manager
    @discardableResult
    public func withAlchemyGasManager(
        config: AlchemyGasManagerConfig, 
        gasEstimationOptions: AlchemyGasEstimationOptions? = nil
    ) throws -> Self {
        let fallbackFeeDataGetter = gasEstimationOptions?.fallbackFeeDataGetter ?? alchemyFeeEstimator
        let fallbackGasEstimator = gasEstimationOptions?.fallbackGasEstimator ?? defaultGasEstimator
        let disableGasEstimation = gasEstimationOptions?.disableGasEstimation ?? false

        let feeDataGetter: ClientMiddlewareFn = if disableGasEstimation {
            fallbackFeeDataGetter
        } else {
            { client, account, uoStruct, overrides in
                var newMaxFeePerGas = uoStruct.maxFeePerGas ?? BigUInt(0)
                var newMaxPriorityFeePerGas = uoStruct.maxPriorityFeePerGas ?? BigUInt(0)

                // but if user is bypassing paymaster to fallback to having the account to pay the gas (one-off override),
                // we cannot delegate gas estimation to the bundler because paymaster middleware will not be called
                if overrides.paymasterAndData == "0x" {
                    let result = try await fallbackFeeDataGetter(client, account, uoStruct, overrides)
                    newMaxFeePerGas = result.maxFeePerGas ?? newMaxFeePerGas
                    newMaxPriorityFeePerGas = result.maxPriorityFeePerGas ?? newMaxPriorityFeePerGas
                }

                var updatedUoStruct = uoStruct
                updatedUoStruct.maxFeePerGas = newMaxFeePerGas
                updatedUoStruct.maxPriorityFeePerGas = newMaxPriorityFeePerGas
                return updatedUoStruct
            }
        }
        withFeeDataGetter(feeDataGetter: feeDataGetter)

        let gasEstimator: ClientMiddlewareFn = if disableGasEstimation {
            fallbackGasEstimator
        } else {
            { client, account, uoStruct, overrides in
                if let modularAccount = account as? ModularAccountV2 {
                    if modularAccount.getMode() == .EIP7702 {
                        return try await default7702GasEstimator(
                            client: client,
                            account: account,
                            userOp: uoStruct,
                            overrides: overrides,
                            continued: defaultGasEstimator
                        )
                    } else {
                        return uoStruct
                    }
                } else {
                    return try await defaultGasEstimator(client, account, uoStruct, overrides)
                }
            }
        }
        withGasEstimator(gasEstimator: gasEstimator)

        let provider = if disableGasEstimation {
            requestPaymasterAndData(provider: self, config: config) as! Self
        } else {
            requestGasAndPaymasterData(provider: self, config: config) as! Self
        };
        
        return provider.withMiddlewareRpcClient(
            rpcClient: try AlchemyProvider.createRpcClient(config: ProviderConfig(chain: chain, connectionConfig: config.connectionConfig))
        ) as! Self
    }
}

/// This uses the alchemy RPC method: `alchemy_requestPaymasterAndData`, which does not estimate gas. It's recommended to use
/// this middleware if you want more customization over the gas and fee estimation middleware, including setting
/// non-default buffer values for the fee/gas estimation.
///
/// @param provider - the smart account provider to override to use the paymaster middleware
/// @param config - the alchemy gas manager configuration
/// @returns the provider augmented to use the paymaster middleware
func requestPaymasterAndData(provider: SmartAccountProvider, config: AlchemyGasManagerConfig) -> SmartAccountProvider {
    provider.withDummyPaymasterMiddleware(
        middleware: { _, _, uoStruct, _ in
            var updatedUoStruct = uoStruct
            let isV060 = (try? provider.getEntryPoint().version) == "0.6.0"
            updatedUoStruct.paymasterAndData = isV060 ? dummyPaymasterAndData(chainId: provider.chain.id) : nil
            return updatedUoStruct
        }
    )
    provider.withPaymasterMiddleware(
        middleware: { client, _, uoStruct, _ in
            let entryPoint = try provider.getEntryPoint().address
            let params = PaymasterAndDataParams(
                policyId: config.policyId,
                entryPoint: entryPoint,
                userOperation: uoStruct.toUserOperationRequest()
            )
            let alchemyClient = client as! AlchemyClient
            var updatedUoStruct = uoStruct
            updatedUoStruct.paymasterAndData = try await alchemyClient.requestPaymasterAndData(params: params).paymasterAndData ?? "0x"
            return updatedUoStruct
        }
    )
    return provider
}


/// This uses the alchemy RPC method: `alchemy_requestGasAndPaymasterAndData` to get all of the gas estimates + paymaster data
/// in one RPC call. It will no-op the gas estimator and fee data getter middleware and set a custom middleware that makes the RPC call.
///
/// @param provider - the smart account provider to override to use the paymaster middleware
/// @param config - the alchemy gas manager configuration
/// @returns the provider augmented to use the paymaster middleware
func requestGasAndPaymasterData(provider: SmartAccountProvider, config: AlchemyGasManagerConfig) -> SmartAccountProvider {
    provider.withDummyPaymasterMiddleware(
        middleware: { _, _, uoStruct, _ in
            var updatedUoStruct = uoStruct
            let isV060 = (try? provider.getEntryPoint().version) == "0.6.0"
            updatedUoStruct.paymasterAndData = isV060 ? dummyPaymasterAndData(chainId: provider.chain.id) : nil
            return updatedUoStruct
        }
    )
    provider.withPaymasterMiddleware(
        middleware: { client, _, uoStruct, overrides in
            let userOperation = uoStruct.toUserOperationRequest()
            let feeOverride = FeeOverride(
                maxFeePerGas: overrides.maxFeePerGas?.properHexString,
                maxPriorityFeePerGas: overrides.maxPriorityFeePerGas?.properHexString,
                callGasLimit: overrides.callGasLimit?.properHexString,
                verificationGasLimit: overrides.verificationGasLimit?.properHexString,
                preVerificationGas: overrides.preVerificationGas?.properHexString
            )

            if let alchemyClient = client as? AlchemyClient {
                let feeOverride: FeeOverride? = if feeOverride.isEmpty { nil } else { feeOverride }
                let result = try await alchemyClient.requestGasAndPaymasterAndData(
                    params: PaymasterAndDataParams(
                        policyId: config.policyId,
                        entryPoint: try provider.getEntryPoint().address,
                        userOperation: userOperation,
                        dummySignature: userOperation.signature,
                        feeOverride: feeOverride
                    )
                )

                var updatedUoStruct = uoStruct
                // v0.6 fields
                if (try? provider.getEntryPoint().version) == "0.6.0" {
                    updatedUoStruct.paymasterAndData = result.paymasterAndData ?? "0x"
                } else {
                    updatedUoStruct.paymasterAndData = nil
                }
                // v0.7 fields
                updatedUoStruct.paymaster = result.paymaster
                updatedUoStruct.paymasterData = result.paymasterData
                updatedUoStruct.paymasterVerificationGasLimit = result.paymasterVerificationGasLimit
                updatedUoStruct.paymasterPostOpGasLimit = result.paymasterPostOpGasLimit
                // Common gas fields
                updatedUoStruct.callGasLimit = result.callGasLimit ?? BigUInt(0)
                updatedUoStruct.verificationGasLimit = result.verificationGasLimit ?? BigUInt(0)
                updatedUoStruct.preVerificationGas = result.preVerificationGas ?? BigUInt(0)
                updatedUoStruct.maxFeePerGas = result.maxFeePerGas ?? BigUInt(0)
                updatedUoStruct.maxPriorityFeePerGas = result.maxPriorityFeePerGas ?? BigUInt(0)
                return updatedUoStruct
            } else {
                return uoStruct
            }
        }
    )
    return provider
}

private func dummyPaymasterAndData(chainId: Int64) -> String {
    switch chainId {
    case Chain.MainNet.id,
        Chain.Optimism.id,
        Chain.Polygon.id,
        Chain.Arbitrum.id: "0x4Fd9098af9ddcB41DA48A1d78F91F1398965addcfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c"
        
    default: "0xc03aac639bb21233e0139381970328db8bceeb67fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c"
    }
}
