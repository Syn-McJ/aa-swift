//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Testing
import Foundation
import BigInt
import web3
import MockSwift
@testable import AASwift

final class BaseSmartContractAccountTest {
    @Mock private var rpcClient: EthereumRPCProtocol
    @Mock private var signer: SmartAccountSigner
    
    @Test
    func encodeGetSenderAddress_returns_correctHex() async throws {
        let scAccount = SimpleSmartContractAccount(rpcClient: rpcClient, factoryAddress: EthereumAddress("0x000000893A26168158fbeaDD9335Be5bC96592E2"), signer: signer, chain: Chain.BaseSepolia)
        let initCode = await scAccount.getAccountInitCode(forAddress: await signer.getAddress())
        let encoded = scAccount.encodeGetSenderAddress(initCode: initCode).web3.hexString
        #expect("0x9b249f6900000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000058000000893a26168158fbeadd9335be5bc96592e25fbfb9cf00000000000000000000000029df43f75149d0552475a6f9b2ac96e28796ed0b00000000000000000000000000000000000000000000000000000000000000000000000000000000".lowercased() == encoded.lowercased())
    }
}
