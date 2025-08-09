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

enum AuthMode {
    case web3Auth
    case privateKey
}

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

class MainViewModel: ObservableObject {
    private let chain = Chain.BaseSepolia
    
    private let jiffyScanBaseUrl = "https://jiffyscan.xyz/userOpHash/"
    private let usdcTokenAddress = "0xCFf7C6dA719408113DFcb5e36182c6d5aa491443"
    
    // replace with your Alchemy API key
    private let alchemyApiKey = "VL04Y5WbMvKHO05PIKtTsmifkEaz8UYU"
    // replace with your Alchemy gas policy ID
    private let alchemyGasPolicyId = "6e224b86-72a7-491b-84b4-b5741e337b10"
    
    // replace with your Web3Auth Client ID
    // these IDs are from Web3Auth example
    private var web3AuthClientId = "BJYIrHuzluClBK0vvTBUJ7kQylV_Dj3NA-X1q4Qvxs2Ay3DySkacOpoOb83lDTHJRVY83bFlYtt4p8pQR-oCYtw"
    private let auth0ClientId = "hUVVf4SEsZT7syOiL0gLU9hFEtm2gQ6O"
    
    // Private key that controls the wallet
    private let PRIVATE_KEY = "0x394add01e3372e6a2752894d5e502810ae59609e53de4f176cee6098b18e4bc6"
    
    // Authentication mode - default to hardcoded private key
    private var authMode: AuthMode = .privateKey
    
    @Published private(set) var uiState = UIState()
    private var web3Auth: Web3Auth!
    private var alchemyToken: ERC20?
    private var scaProvider: ISmartAccountProvider?

    init() {
        Task {
            if authMode == .privateKey {
                // Use hardcoded private key directly
                self.setKeyStateWithPrivateKey(privateKey: PRIVATE_KEY)
            } else {
                // Initialize Web3Auth for future use
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
    }
    
    func login() {
        if authMode == .privateKey {
            // Already logged in with hardcoded key, do nothing
            return
        }
        
        Task {
            do {
                let result = try await web3Auth?.login(
                    W3ALoginParams(
                        loginProvider: .JWT,
                        dappShare: nil,
                        extraLoginOptions: ExtraLoginOptions(display: nil, prompt: nil, max_age: nil, ui_locales: nil, id_token_hint: nil, id_token: nil, login_hint: nil, acr_values: nil, scope: nil, audience: nil, connection: nil, domain: "https://web3auth.au.auth0.com", client_id: nil, redirect_uri: nil, leeway: nil, verifierIdField: "sub", isVerifierIdCaseSensitive: nil, additionalParams: [:]),
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
        if authMode == .privateKey {
            // Cannot logout with hardcoded key
            return
        }
        
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
            } catch let bundlerError as BundlerClientError {
                self.uiState.step = .error
                let errorMessage: String
                if case .executionError(let result) = bundlerError.underlyingError {
                    errorMessage = result.message
                } else {
                    errorMessage = bundlerError.underlyingError.localizedDescription
                }
                self.uiState.error = "Error in \(bundlerError.methodName): \(errorMessage)"
                print("BundlerClientError - Method: \(bundlerError.methodName), Error: \(errorMessage)")
            } catch let providerError as SmartAccountProviderError {
                self.uiState.step = .error
                let errorMessage: String
                switch providerError {
                case .notConnected(let message):
                    errorMessage = message
                case .noRpc(let message):
                    errorMessage = message
                case .noParameters(let message):
                    errorMessage = message
                case .noTransaction(let message):
                    errorMessage = message
                }
                self.uiState.error = "SmartAccountProvider: \(String(errorMessage.prefix(50)))"
                print("SmartAccountProviderError: \(errorMessage)")
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
    
    private func setKeyStateWithPrivateKey(privateKey: String) {
        Task {
            let keyStorage = EthereumKeyLocalStorage()
            let cleanPrivateKey = privateKey.hasPrefix("0x") ? String(privateKey.dropFirst(2)) : privateKey
            if let account = try? EthereumAccount.importAccount(replacing: keyStorage, privateKey: cleanPrivateKey, keystorePassword: "") {
                self.setupSmartContractAccount(credentials: account)
                self.uiState.step = .ready
                self.uiState.address = try? await self.scaProvider?.getAddress().asString()
            } else {
                self.uiState.step = .error
                self.uiState.error = "Failed to import private key"
            }
        }
    }

    private func setupSmartContractAccount(credentials: EthereumAccount) {
        do {
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

            let signer = LocalAccountSigner()
            let account = ModularAccountV2(
                rpcClient: provider.rpcClient,
                factoryAddress: nil,
                signer: signer,
                chain: chain,
                mode: .EIP7702
            )

            signer.setCredentials(credentials)
            provider.connect(account: account)
            self.scaProvider = provider
            self.alchemyToken = ERC20(client: provider.rpcClient)
        } catch {
            setKeyState(loggedIn: false, error: error)
        }
    }

    private func sendMintUserOperation(provider: ISmartAccountProvider) async throws -> String {
        let encodedFn = ABIFunctionEncoder("mint")
        try encodedFn.encode(try await provider.getAddress())
        try encodedFn.encode(BigUInt("11700000000000000000000"))
        let encoded = try encodedFn.encoded()
        
        return try await provider.sendUserOperation(
            data: UserOperationCallData(
                target: EthereumAddress(usdcTokenAddress),
                data: encoded
            ),
            overrides: UserOperationOverrides()
        ).hash
    }

    private func refreshAlchemyTokenBalance() async throws {
        if let userAddress = try await scaProvider?.getAddress() {
            let balance = try await self.alchemyToken?.balanceOf(tokenContract: EthereumAddress(usdcTokenAddress), address: userAddress) ?? BigUInt(0)
            let decimalValue = Double(balance)
            let divisor = Double(BigUInt(10).power(18))
            let result = decimalValue / divisor
            self.uiState.balance = String(describing: result)
        }
    }
}
