//
//  Copyright (c) 2024 aa-swift
//
//  This file is part of the aa-swift project: https://github.com/syn-mcj/aa-swift,
//  and is released under the MIT License: https://opensource.org/licenses/MIT
//

import AASwift
import AASwiftAlchemy
import Combine
import Web3Auth
import Foundation
import web3
import BigInt

enum Step: Comparable {
    case notStarted
    case key
    case address
    case ready
    case minting
    case confirming
    case done
    case error
}

struct UIState: Equatable {
    var step: Step = .notStarted
    var address: String?
    var error: String?
    var balance: String?
    var explorerLink: String?
}

class MainViewModel {
    private let chain = Chain.Sepolia // Alchemy token is deployed on Sepolia
    
    private let jiffyScanBaseUrl = "https://jiffyscan.xyz/userOpHash/"
    private let alchemyTokenSepoliaAddress = "0x6F3c1baeF15F2Ac6eD52ef897f60cac0B10d90C3"
    
    // replace with your Alchemy API key
    private let alchemyApiKey = "VL04Y5WbMvKHO05PIKtTsmifkEaz8UYU"
    // replace with your Alchemy gas policy ID
    private let alchemyGasPolicyId = "fc1342bf-c475-43b8-af42-d7b3cd189e59"
    
    // replace with your Web3Auth Client ID
    // these IDs are from Web3Auth example
    private var web3AuthClientId = "BHr_dKcxC0ecKn_2dZQmQeNdjPgWykMkcodEHkVvPMo71qzOV6SgtoN8KCvFdLN7bf34JOm89vWQMLFmSfIo84A"
    private let auth0ClientId = "294QRkchfq2YaXUbPri7D6PH7xzHgQMT"
    
    @Published private(set) var uiState = UIState()
    private var web3Auth: Web3Auth!
    private var alchemyToken: ERC20?
    private var scaProvider: ISmartAccountProvider?

    init() {
        Task {
            self.web3Auth = await Web3Auth(.init(
                clientId: web3AuthClientId,
                network: .testnet,
                loginConfig: [
                    TypeOfLogin.jwt.rawValue: .init(
                        verifier: "web3auth-auth0-example",
                        typeOfLogin: .jwt,
                        name: "Web3Auth-Auth0-JWT",
                        clientId: auth0ClientId
                    )
                ])
            )
            
            if self.web3Auth?.state?.privKey?.isEmpty == false {
                setKeyState(loggedIn: true, error: nil)
            }
        }
    }
    
    func login() {
        Task {
            do {
                let result = try await web3Auth?.login(
                    W3ALoginParams(
                        loginProvider: .JWT,
                        dappShare: nil,
                        extraLoginOptions: ExtraLoginOptions(display: nil, prompt: nil, max_age: nil, ui_locales: nil, id_token_hint: nil, id_token: nil, login_hint: nil, acr_values: nil, scope: nil, audience: nil, connection: nil, domain: "https://shahbaz-torus.us.auth0.com", client_id: nil, redirect_uri: nil, leeway: nil, verifierIdField: "sub", isVerifierIdCaseSensitive: nil, additionalParams: [:]),
                        mfaLevel: .NONE,
                        curve: .SECP256K1
                    ))
                setKeyState(loggedIn: result?.privKey?.isEmpty == false, error: nil)
            } catch Web3AuthError.userCancelled {
                setKeyState(loggedIn: false, error: nil)
            } catch {
                setKeyState(loggedIn: false, error: error)
            }
        }
    }

    func logout() {
        Task {
            do {
                try await web3Auth.logout()
                self.setKeyState(loggedIn: false, error: nil)
            } catch {
                self.setKeyState(loggedIn: false, error: error)
            }
        }
    }

    func mint() {
        guard let provider = scaProvider else { return }
        uiState.step = .minting
        
        Task {
            do {
                let resultHash = try await self.sendMintUserOperation(provider: provider)
                self.uiState.step = .confirming
                try await provider.waitForUserOperationTransaction(hash: resultHash)
                self.uiState.step = .done
                self.uiState.explorerLink = jiffyScanBaseUrl + resultHash
                try await self.refreshAlchemyTokenBalance()
            } catch JSONRPCError.executionError(let errorResult) {
                self.uiState.step = .error
                self.uiState.error = errorResult.error.message
            } catch {
                self.uiState.step = .error
                self.uiState.error = error.localizedDescription
            }
        }
    }
    
    private func setKeyState(loggedIn: Bool, error: Error?) {
        Task {
            if error == nil {
                if loggedIn && !web3Auth.getPrivkey().isEmpty {
                    let keyStorage = EthereumKeyLocalStorage()
                    if let account = try? EthereumAccount.importAccount(replacing: keyStorage, privateKey: web3Auth.getPrivkey(), keystorePassword: "") {
                        self.setupSmartContractAccount(credentials: account)
                        self.uiState.step = .ready
                        self.uiState.address = try? await self.scaProvider?.getAddress().asString()
                    }
                } else {
                    self.uiState.step = .notStarted
                }
            } else {
                self.uiState.step = .error
                self.uiState.error = error?.localizedDescription ?? "Error while fetching key"
            }
        }
    }

    private func setupSmartContractAccount(credentials: EthereumAccount) {
        do {
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

            let account = try LightSmartContractAccount(
                rpcClient: provider.rpcClient,
                entryPointAddress: chain.getDefaultEntryPointAddress(),
                factoryAddress: chain.getDefaultLightAccountFactoryAddress(),
                signer: LocalAccountSigner(account: credentials),
                chain: chain
            )

            provider.connect(account: account)
            self.scaProvider = provider
            self.alchemyToken = ERC20(client: provider.rpcClient)
        } catch {
            setKeyState(loggedIn: false, error: error)
        }
    }

    private func sendMintUserOperation(provider: ISmartAccountProvider) async throws -> String {
        let encodedFn = ABIFunctionEncoder("mint")
        try await encodedFn.encode(provider.getAddress())
        
        return try await provider.sendUserOperation(
            data: [
                UserOperationCallData(
                    target: EthereumAddress(alchemyTokenSepoliaAddress),
                    data: encodedFn.encoded()
                ),
                UserOperationCallData(
                    target: EthereumAddress(alchemyTokenSepoliaAddress),
                    data: encodedFn.encoded()
                )
            ],
            overrides: UserOperationOverrides()
        ).hash
    }

    private func refreshAlchemyTokenBalance() async throws {
        if let userAddress = try await scaProvider?.getAddress() {
            let balance = try await self.alchemyToken?.balanceOf(tokenContract: EthereumAddress(alchemyTokenSepoliaAddress), address: userAddress) ?? BigUInt(0)
            let decimalValue = Double(balance)
            let divisor = Double(BigUInt(10).power(18))
            let result = decimalValue / divisor
            self.uiState.balance = String(describing: result)
        }
    }
}
