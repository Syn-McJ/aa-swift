import Foundation
import web3
import BigInt

/// Tuple structure for ModularAccountV2's executeBatch function
/// Represents (address, uint256, bytes) tuple
struct ExecuteBatchTuple: ABITuple {
    static var types: [ABIType.Type] { 
        [EthereumAddress.self, BigUInt.self, Data.self] 
    }
    
    let target: EthereumAddress
    let value: BigUInt
    let data: Data
    
    init(target: EthereumAddress, value: BigUInt, data: Data) {
        self.target = target
        self.value = value
        self.data = data
    }
    
    init?(values: [ABIDecoder.DecodedValue]) throws {
        self.target = try values[0].decoded()
        self.value = try values[1].decoded()
        self.data = try values[2].decoded()
    }
    
    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(target)
        try encoder.encode(value)
        try encoder.encode(data)
    }
    
    var encodableValues: [ABIType] { 
        [target, value, data] 
    }
}