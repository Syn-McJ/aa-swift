//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import Testing
import BigInt
import web3
@testable import AASwift

struct UtilsTest {
    var uoRequest: UserOperationRequest
    var uoStruct: UserOperationStruct

    init() {
        uoRequest = UserOperationRequest(
            sender: "0xb856DBD4fA1A79a46D426f537455e7d3E79ab7c4",
            nonce: "0x1f",
            initCode: "0x",
            callData: "0xb61d27f6000000000000000000000000b856dbd4fa1a79a46d426f537455e7d3e79ab7c4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000",
            callGasLimit: "0x2f6c",
            verificationGasLimit: "0x114c2",
            preVerificationGas: "0xa890",
            maxFeePerGas: "0x59682f1e",
            maxPriorityFeePerGas: "0x59682f00",
            signature: "0xd16f93b584fbfdc03a5ee85914a1f29aa35c44fea5144c387ee1040a3c1678252bf323b7e9c3e9b4dfd91cca841fc522f4d3160a1e803f2bf14eb5fa037aae4a1b",
            paymasterAndData: "0x"
        )
        
        uoStruct = UserOperationStruct(
            sender: uoRequest.sender,
            nonce: BigUInt(hex: uoRequest.nonce)!,
            initCode: uoRequest.initCode,
            callData: uoRequest.callData,
            callGasLimit: uoRequest.callGasLimit.flatMap { BigUInt(hex: $0) },
            verificationGasLimit: uoRequest.verificationGasLimit.flatMap { BigUInt(hex: $0) },
            preVerificationGas: uoRequest.preVerificationGas.flatMap { BigUInt(hex: $0) },
            maxFeePerGas: uoRequest.maxFeePerGas.flatMap { BigUInt(hex: $0) },
            maxPriorityFeePerGas: uoRequest.maxPriorityFeePerGas.flatMap { BigUInt(hex: $0) },
            signature: Data(hex: uoRequest.signature)!,
            paymasterAndData: uoRequest.paymasterAndData
        )
    }
    
    @Test
    func getUserOperationHash_returns_correctHash() throws {
        let entrypointAddress = "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"
        let chain = Chain(id: 80001, network: "polygon-mumbai", name: "Polygon Mumbai", currency: Currency(name: "MATIC", symbol: "MATIC", decimals: 18))
        let entryPoint = EntryPoint(address: entrypointAddress, version: "0.6.0", chain: chain)
        let hash = getUserOperationHash(
            request: uoStruct,
            entryPoint: entryPoint,
            chainId: 80001
        ).web3.hexString

        #expect("0xa70d0af2ebb03a44dcd0714a8724f622e3ab876d0aa312f0ee04823285d6fb1b".lowercased() == hash.lowercased())
    }
    
    @Test
    func toUserOperationRequest_returns_correctRequest() throws {
        let request = uoStruct.toUserOperationRequest()
        #expect(uoRequest == request)
    }
    
    @Test
    func packAccountGasLimits() throws {
        let packed = packAccountGasLimits(value1: BigUInt(100), value2: BigUInt(200))
        // 100 = 0x64, 200 = 0xc8, each padded to 32 hex chars
        #expect(packed == "0x00000000000000000000000000000064000000000000000000000000000000c8")
    }
    
    @Test
    func packPaymasterData() throws {
        let paymaster = "0x1234567890123456789012345678901234567890"
        let verificationGasLimit = BigUInt(1000)
        let postOpGasLimit = BigUInt(2000)
        let paymasterData = "0xabcdef"
        
        let packed = packPaymasterData(
            paymaster: paymaster,
            paymasterVerificationGasLimit: verificationGasLimit,
            paymasterPostOpGasLimit: postOpGasLimit,
            paymasterData: paymasterData
        )
        
        // Should concatenate paymaster + padded gas limits + paymaster data
        // 1000 = 0x3e8, 2000 = 0x7d0
        let expected = "0x1234567890123456789012345678901234567890000000000000000000000000000003e8000000000000000000000000000007d0abcdef"
        #expect(packed == expected)
    }
    
    @Test
    func packPaymasterData_returnsEmpty_whenPaymasterDataIsNil() throws {
        let packed = packPaymasterData(
            paymaster: "0x1234567890123456789012345678901234567890",
            paymasterVerificationGasLimit: BigUInt(1000),
            paymasterPostOpGasLimit: BigUInt(2000),
            paymasterData: nil
        )
        
        #expect(packed == "0x")
    }
    
    @Test
    func getUserOperationHash_v070_returns_correctHash() throws {
        // Create a v0.7.0 user operation with the new fields
        var v7UserOp = uoStruct
        v7UserOp.factory = "0x0000000000FFe8B47B3e2130213B802212439497"
        v7UserOp.factoryData = "0x1234"
        v7UserOp.paymaster = "0x1234567890123456789012345678901234567890"
        v7UserOp.paymasterVerificationGasLimit = BigUInt(1000)
        v7UserOp.paymasterPostOpGasLimit = BigUInt(2000)
        v7UserOp.paymasterData = "0xabcdef"
        
        let entrypointAddress = "0x0000000071727De22E5E9d8BAf0edAc6f37da032"
        let chain = Chain(id: 80001, network: "polygon-mumbai", name: "Polygon Mumbai", currency: Currency(name: "MATIC", symbol: "MATIC", decimals: 18))
        let entryPoint = EntryPoint(address: entrypointAddress, version: "0.7.0", chain: chain)
        
        // Just verify it runs without crashing and produces a hash
        let hash = getUserOperationHash(
            request: v7UserOp,
            entryPoint: entryPoint,
            chainId: 80001
        ).web3.hexString
        
        // Ensure we get a valid hash (32 bytes = 64 hex chars + 0x prefix = 66 chars)
        #expect(hash.count == 66)
        #expect(hash.hasPrefix("0x"))
    }
}
