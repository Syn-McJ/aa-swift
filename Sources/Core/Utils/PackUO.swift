//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import web3
import Foundation
import BigInt

/**
 * Generates a hash for a UserOperation valid from entrypoint version 0.6 onwards
 *
 * - Parameter request: the UserOperation to get the hash for
 * - Parameter entryPoint: the entry point that will be used to execute the UserOperation
 * - Parameter chainId: the chain on which this UserOperation will be executed
 * - Returns: the hash of the UserOperation
 */
public func getUserOperationHash(
    request: UserOperationStruct,
    entryPoint: EntryPoint,
    chainId: Int64
) -> Data {
    let packed = entryPoint.version == "0.7.0" ? packUOv070(request: request) : packUOv060(request: request)
    
    let array = ABIEncoder.EncodedValue.container(values: [
        try! ABIEncoder.encode(Data32(data: packed.web3.keccak256)),
        try! ABIEncoder.encode(EthereumAddress(entryPoint.address)),
        try! ABIEncoder.encode(BigUInt(chainId)),
    ], isDynamic: true, size: nil)
    
    return Data(array.bytes).web3.keccak256
}

private func packUOv060(request: UserOperationStruct) -> Data {
    let hashedInitCode = Data(hex: request.initCode ?? "0x")!.web3.keccak256
    let hashedCallData = Data(hex: request.callData)!.web3.keccak256
    let hashedPaymasterAndData = Data(hex: request.paymasterAndData ?? "0x")!.web3.keccak256
    
    let array = ABIEncoder.EncodedValue.container(values: [
        try! ABIEncoder.encode(EthereumAddress(request.sender)),
        try! ABIEncoder.encode(request.nonce),
        try! ABIEncoder.encode(Data32(data: hashedInitCode)),
        try! ABIEncoder.encode(Data32(data: hashedCallData)),
        try! ABIEncoder.encode(request.callGasLimit!),
        try! ABIEncoder.encode(request.verificationGasLimit!),
        try! ABIEncoder.encode(request.preVerificationGas!),
        try! ABIEncoder.encode(request.maxFeePerGas!),
        try! ABIEncoder.encode(request.maxPriorityFeePerGas!),
        try! ABIEncoder.encode(Data32(data: hashedPaymasterAndData)),
    ], isDynamic: true, size: nil)
    
    return Data(array.bytes)
}

private func packUOv070(request: UserOperationStruct) -> Data {
    let initCode: String
    if let factory = request.factory, let factoryData = request.factoryData {
        initCode = concatHex(values: [factory, factoryData])
    } else {
        initCode = "0x"
    }
    let hashedInitCode = Data(hex: initCode)!.web3.keccak256
    
    let accountGasLimits = packAccountGasLimits(
        value1: request.verificationGasLimit ?? 0,
        value2: request.callGasLimit ?? 0
    )
    let gasFees = packAccountGasLimits(
        value1: request.maxPriorityFeePerGas ?? 0,
        value2: request.maxFeePerGas ?? 0
    )
    
    let paymasterAndData: String
    if let paymaster = request.paymaster {
        paymasterAndData = packPaymasterData(
            paymaster: paymaster,
            paymasterVerificationGasLimit: request.paymasterVerificationGasLimit ?? 0,
            paymasterPostOpGasLimit: request.paymasterPostOpGasLimit ?? 0,
            paymasterData: request.paymasterData
        )
    } else {
        paymasterAndData = "0x"
    }
    let hashedCallData = Data(hex: request.callData)!.web3.keccak256
    let hashedPaymasterAndData = Data(hex: paymasterAndData)!.web3.keccak256
    
    let array = ABIEncoder.EncodedValue.container(values: [
        try! ABIEncoder.encode(EthereumAddress(request.sender)),
        try! ABIEncoder.encode(request.nonce),
        try! ABIEncoder.encode(Data32(data: hashedInitCode)),
        try! ABIEncoder.encode(Data32(data: hashedCallData)),
        try! ABIEncoder.encode(Data32(data: Data(hex: accountGasLimits)!)),
        try! ABIEncoder.encode(request.preVerificationGas!),
        try! ABIEncoder.encode(Data32(data: Data(hex: gasFees)!)),
        try! ABIEncoder.encode(Data32(data: hashedPaymasterAndData)),
    ], isDynamic: true, size: nil)
    
    return Data(array.bytes)
}

/**
 * Packs two BigUInt values into a single hex string, with each value padded to 16 bytes (32 hex chars).
 * Used for packing gas limits and fee values in EntryPoint v0.7.
 */
public func packAccountGasLimits(value1: BigUInt, value2: BigUInt) -> String {
    let hex1 = padHex(hex: value1.web3.hexStringNoLeadingZeroes.web3.noHexPrefix, length: 32)
    let hex2 = padHex(hex: value2.web3.hexStringNoLeadingZeroes.web3.noHexPrefix, length: 32)
    return "0x\(hex1)\(hex2)"
}

/**
 * Packs paymaster data for EntryPoint v0.7.
 * Concatenates paymaster address with padded gas limits and paymaster data.
 */
public func packPaymasterData(
    paymaster: String,
    paymasterVerificationGasLimit: BigUInt,
    paymasterPostOpGasLimit: BigUInt,
    paymasterData: String?
) -> String {
    guard let paymasterData = paymasterData else {
        return "0x"
    }
    
    let verificationGasLimitHex = padHex(hex: paymasterVerificationGasLimit.web3.hexStringNoLeadingZeroes.web3.noHexPrefix, length: 32)
    let postOpGasLimitHex = padHex(hex: paymasterPostOpGasLimit.web3.hexStringNoLeadingZeroes.web3.noHexPrefix, length: 32)
    
    return concatHex(values: [
        paymaster,
        "0x\(verificationGasLimitHex)",
        "0x\(postOpGasLimitHex)",
        paymasterData
    ])
}

/**
 * Left-pads a hex string to the specified length.
 * 
 * - Parameter hex: The hex string to pad (without 0x prefix)
 * - Parameter length: The target length in characters
 * - Returns: The padded hex string
 */
private func padHex(hex: String, length: Int) -> String {
    return String(repeating: "0", count: max(0, length - hex.count)) + hex
}
