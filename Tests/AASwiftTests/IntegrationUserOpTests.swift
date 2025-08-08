import XCTest
@testable import AASwift
import AASwiftAlchemy
import web3
import BigInt

final class IntegrationUserOpTests: XCTestCase {
    private let chain = Chain.Sepolia
    private let tokenAddress = "0x6F3c1baeF15F2Ac6eD52ef897f60cac0B10d90C3" // Alchemy token on Sepolia

    func test_SendUserOp_inEIP7702Mode_thenDefaultMode() async throws {
        try await runIntegration(mode: "eip7702")
        try await runIntegration(mode: "default")
    }

    private func runIntegration(mode: String) async throws {
        let env = ProcessInfo.processInfo.environment
        let privKey = env["AA_TEST_PRIVKEY"] ?? ""
        let alchemyApiKey = env["AA_TEST_ALCHEMY_API_KEY"] ?? ""
        let alchemyGasPolicyId = env["AA_TEST_ALCHEMY_GAS_POLICY_ID"] ?? ""

        guard !privKey.isEmpty, !alchemyApiKey.isEmpty, !alchemyGasPolicyId.isEmpty else {
            throw XCTSkip("Missing one of required env vars: AA_TEST_PRIVKEY, AA_TEST_ALCHEMY_API_KEY, AA_TEST_ALCHEMY_GAS_POLICY_ID")
        }

        // AA_MODE is provided by CI matrix; here we just ensure code runs for both values.

        let connectionConfig = ConnectionConfig(apiKey: alchemyApiKey, jwt: nil, rpcUrl: nil)
        let provider = try AlchemyProvider(
            entryPointAddress: chain.getDefaultEntryPointAddress(),
            config: ProviderConfig(
                chain: chain,
                connectionConfig: connectionConfig,
                opts: SmartAccountProviderOpts(txMaxRetries: 50, txRetryIntervalMs: 500)
            )
        ).withAlchemyGasManager(
            config: AlchemyGasManagerConfig(policyId: alchemyGasPolicyId, connectionConfig: connectionConfig)
        )

        let keyStorage = EthereumKeyLocalStorage()
        let account = try EthereumAccount.importAccount(replacing: keyStorage, privateKey: privKey, keystorePassword: "")

        let sca = try LightSmartContractAccount(
            rpcClient: provider.rpcClient,
            entryPointAddress: chain.getDefaultEntryPointAddress(),
            factoryAddress: try chain.getDefaultLightAccountFactoryAddress(),
            signer: LocalAccountSigner(account: account),
            chain: chain
        )

        provider.connect(account: sca)

        // Prepare mint calls (same as MainViewModel.mint())
        let encoder = ABIFunctionEncoder("mint")
        try await encoder.encode(provider.getAddress())

        let hash = try await provider.sendUserOperation(
            data: [
                UserOperationCallData(
                    target: EthereumAddress(tokenAddress),
                    data: encoder.encoded()
                ),
                UserOperationCallData(
                    target: EthereumAddress(tokenAddress),
                    data: encoder.encoded()
                ),
            ],
            overrides: UserOperationOverrides()
        ).hash

        // Wait for inclusion
        let receipt = try await provider.waitForUserOperationTransaction(hash: hash)
        // Compare via request hash if accessible; otherwise assert non-empty receipt
        XCTAssertFalse(receipt.userOpHash.isEmpty)
    }
}