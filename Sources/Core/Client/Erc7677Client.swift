//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Foundation

/// ERC-7677 Client protocol for paymaster interactions
/// 
/// ERC-7677 defines a standard for paymaster interactions that allows
/// smart contract accounts to get paymaster stub data for gas sponsorship.
/// This protocol provides a consistent interface for ERC-7677 operations
/// across different providers.
///
/// - SeeAlso: [ERC-7677: Paymaster Web API](https://eips.ethereum.org/EIPS/eip-7677)
public protocol Erc7677Client {
    /// Requests paymaster stub data for a user operation
    ///
    /// This method implements the `pm_getPaymasterStubData` RPC method defined in ERC-7677.
    /// It returns paymaster and data information that can be used to sponsor a user operation.
    ///
    /// - Parameter params: The paymaster data request parameters containing the user operation,
    ///                    entry point address, chain ID, and optional policy information
    /// - Returns: PaymasterData containing the paymaster address and associated data
    /// - Throws: An error if the request fails or returns invalid data
    func getPaymasterStubData(params: PaymasterDataParams) async throws -> PaymasterData
}