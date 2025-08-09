import Testing
import Foundation
@testable import AASwift
import AASwiftAlchemy
import web3
import BigInt

final class IntegrationUserOpTests {
    private let chain = Chain.BaseSepolia
    private let tokenAddress = "0xCFf7C6dA719408113DFcb5e36182c6d5aa491443" // USDC on Base Sepolia (example)
    private let alchemyApiKey: String = "VL04Y5WbMvKHO05PIKtTsmifkEaz8UYU"
    private let alchemyGasPolicyId: String = "6e224b86-72a7-491b-84b4-b5741e337b10"
    private let privateKey: String = "0x394add01e3372e6a2752894d5e502810ae59609e53de4f176cee6098b18e4bc6"

    @Test
    func SendUserOp_respectsAAModeFromEnv() async throws {
        try await runIntegration()
    }

    private func runIntegration() async throws {
        let connectionConfig = ConnectionConfig(apiKey: alchemyApiKey, jwt: nil, rpcUrl: nil)
        let provider = try AlchemyProvider(
            config: ProviderConfig(
                chain: chain,
                connectionConfig: connectionConfig,
                opts: SmartAccountProviderOpts(txMaxRetries: 50, txRetryIntervalMs: 500)
            )
        ).withAlchemyGasManager(
            config: AlchemyGasManagerConfig(policyId: alchemyGasPolicyId, connectionConfig: connectionConfig)
        ).erc7677Middleware(policyId: alchemyGasPolicyId)

        let keyStorage = EthereumKeyLocalStorage()
        let account = try EthereumAccount.importAccount(replacing: keyStorage, privateKey: privateKey, keystorePassword: "")

        let signer = LocalAccountSigner()
        signer.setCredentials(account)

        // Determine account mode from AA_MODE env var
        let aaModeEnv = ProcessInfo.processInfo.environment["AA_MODE"]?.lowercased()
        let accountMode: AccountMode = (aaModeEnv == "eip7702") ? .EIP7702 : .DEFAULT

        let modular = ModularAccountV2(
            rpcClient: provider.rpcClient,
            factoryAddress: nil,
            signer: signer,
            chain: chain,
            mode: accountMode
        )

        provider.connect(account: modular)

        // Prepare mint call (same as MainViewModel.mint())
        let encoder = ABIFunctionEncoder("mint")
        try await encoder.encode(provider.getAddress())
        try encoder.encode(BigUInt("11700000000000000000000"))

        let hash = try await provider.sendUserOperation(
            data: UserOperationCallData(
                target: EthereumAddress(tokenAddress),
                data: encoder.encoded()
            ),
            overrides: UserOperationOverrides()
        ).hash

        // Wait for inclusion
        let receipt = try await provider.waitForUserOperationTransaction(hash: hash)
        #expect(!receipt.userOpHash.isEmpty)
    }
}
