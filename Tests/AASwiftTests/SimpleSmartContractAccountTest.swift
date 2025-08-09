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

final class SimpleSmartContractAccountTest {
    @Mock private var rpcClient: EthereumRPCProtocol
    @Mock private var signer: SmartAccountSigner
    
    @Test
    func getAccountInitCode_returns_correctHex() async throws {
        let scAccount = SimpleSmartContractAccount(rpcClient: rpcClient, factoryAddress: EthereumAddress("0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"), signer: signer, chain: Chain.Polygon)
        let result = await scAccount.getAccountInitCode(forAddress: await signer.getAddress())
        #expect("0x5FF137D4b0FDCD49DcA30c7CF57E578a026d27895fbfb9cf00000000000000000000000029df43f75149d0552475a6f9b2ac96e28796ed0b0000000000000000000000000000000000000000000000000000000000000000".lowercased() == result.lowercased())
    }
    
    @Test
    func encodeExecute_returns_correctHex() async throws {
        let scAccount = SimpleSmartContractAccount(rpcClient: rpcClient, factoryAddress: EthereumAddress("0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"), signer: signer, chain: Chain.Polygon)
        let result = await scAccount.encodeExecute(target: EthereumAddress("0x8C8D7C46219D9205f056f28fee5950aD564d7465"), value: BigUInt(0), data: Data(hex: "68656C6C6F20776F726C64")!)
        #expect("0xb61d27f60000000000000000000000008c8d7c46219d9205f056f28fee5950ad564d746500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000b68656c6c6f20776f726c64000000000000000000000000000000000000000000".lowercased() == result.lowercased())
    }
}
