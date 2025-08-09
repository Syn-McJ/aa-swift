//
//  Copyright (c) 2025 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift

public protocol CoinbaseClient: BundlerClient, Erc7677Client {
    func getPaymasterData(params: AASwift.PaymasterDataParams) async throws -> PaymasterData
    func sponsorUserOperation(userOp: UserOperationRequest, entryPoint: String) async throws -> SponsoredUserOperation
}
