//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import web3
import BigInt

public protocol BundlerClient: EthereumRPCProtocol {
    /**
     * calls eth_estimateUserOperationGas and  returns the result
     *
     * - Parameter request: the `UserOperationRequest` to estimate gas for
     * - Parameter entryPoint: the entrypoint address the op will be sent to
     * - Returns: the gas estimates for the given response (see: `EstimateUserOperationGasResponse`)
     */
    func estimateUserOperationGas(
        request: UserOperationRequest,
        entryPoint: String
    ) async throws -> EstimateUserOperationGasResponse

    /**
     * calls eth_sendUserOperation and returns the hash of the sent UserOperation
     *
     * - Parameter request: the `UserOperationRequest` to send
     * - Parameter entryPoint: the entrypoint address the op will be sent to
     * - Returns: the hash of the sent UserOperation
     */
    func sendUserOperation(
        request: UserOperationRequest,
        entryPoint: String
    ) async throws -> String

    /**
     * calls `eth_getUserOperationReceipt` and returns the `UserOperationReceipt`
     *
     * - Parameter hash: the hash of the UserOperation to get the receipt for
     * - Returns: `UserOperationResponse`
     */
    func getUserOperationReceipt(hash: String) async throws -> UserOperationReceipt

    /**
     * Returns an estimate for the fees per gas (in wei) for a
     * transaction to be likely included in the next block.
     * Defaults to [`chain.fees.estimateFeesPerGas`](/docs/clients/chains.html#fees-estimatefeespergas) if set.
     *
     * - Docs: https://viem.sh/docs/actions/public/estimateFeesPerGas.html
     *
     * - Returns: An estimate (in wei) for the fees per gas.
     */
    func estimateFeesPerGas(chain: Chain) async throws -> FeeValuesEIP1559
    
    /// Returns a fee per gas that is an estimate of how much you can pay as a priority fee, or 'tip', to get a transaction included in the current block.
    func eth_maxPriorityFeePerGas() async throws -> BigUInt
    
    // Temporary method untill web3.swift changes are released
    func eth_getBlockFeeInfoByNumber(_ block: EthereumBlock) async throws -> EthereumBlockFeeInfo
}
