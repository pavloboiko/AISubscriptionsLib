//
//  MyAccountModel.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 1/29/21.
//

import Foundation
import AuthenticationServices

public enum MyAccountAlertType {
    case succesRegistred
    case failedRegistred
    case failedAppleRegistration(Error)
    case invalidEmail
}

public protocol MyAccountViewModelInput {
    var user: User? { get }
    var appInfo: AppInfoProtocol { get }
    func registerWith(email: String, name: String?)
    func logout()
}

public protocol MyAccountViewModelOutput {
    func updateData()
    func presentAlert(by type: MyAccountAlertType)
}

public class MyAccountViewModel: NSObject, MyAccountViewModelInput {
    
    public var user: User?
    var storageService: StorageServiceProtocol
    var userService: UserServiceProtocol
    public var appInfo: AppInfoProtocol
    public var output: MyAccountViewModelOutput?
    
    public override init() {
       
        self.storageService = StorageService()
        let apiService = APIService(storage: self.storageService)
        self.userService = UserService(apiManager: apiService, storage: self.storageService)
        self.appInfo = AppInfoService(apiService: apiService, storage: self.storageService)
        super.init()

        user = self.storageService.user
        if var user = user {
            userService.register(user: user, confirmation: false) { [weak self] success in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.user = self.storageService.user
                    self.output?.updateData()
                    self.checkCredential()
                }
            }
        }
    }
    
    func checkCredential() {
        if #available(iOS 13.0, *) {
            guard let user = user,
                  user.source == .siwa,
                  let userID = user.userID else {
                CLog.print(.description, .myAccount, "Not authorize with siwa")
                return
            }
            
            userService.checkCredential(by: userID) { [weak self] result in
                guard let self = self else { return }
                if case .failure = result {
                    DispatchQueue.main.async {
                        self.user = nil
                        self.output?.updateData()
                    }
                }
            }
        }
    }
    
    func register(user: User) {
        userService.register(user: user, confirmation: true) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if case .success(let success) = result, success {
                    self.user = self.storageService.user
                    self.output?.presentAlert(by: .succesRegistred)
                    self.output?.updateData()
                    
                } else {
                    self.output?.presentAlert(by: .failedRegistred)
                }
            }
        }
    }
    
    public func registerWith(email: String, name: String?) {
        guard let deviceID = storageService.deviceID?.key else {
            CLog.print(.description, .myAccount, "Submit failed because Not found deviceID")
            return
        }
        var user = User(deviceID: deviceID,
                        email: email,
                        source: .sev)
        user.name = name ?? ""
        register(user: user)
    }
    
    func registerWith(uid: String,
                      authCode: Data?,
                      idenToken: Data?,
                      givenName: String?,
                      familyName: String?,
                      email: String?) {
        guard let deviceID = storageService.deviceID?.key else {
            CLog.print(.description, .myAccount, "Apple sign in failed because Not found deviceID")
            return
        }
        var user = User(deviceID: deviceID,
                        userID: uid,
                        source: .siwa)
        user.givenName = givenName
        user.familyName = familyName
        user.email = email
        if let data = authCode {
            user.authCode = String(decoding: data, as: UTF8.self)
        }
        if let dataToken = idenToken {
            let tokenString = String(decoding: dataToken, as: UTF8.self)
            user.idenToken = tokenString
            if let dict =  try? HMACHelper.decode(jwtToken: tokenString) {
                if user.email == nil,
                   let tokenEmail = dict["email"] as? String {
                    user.email = tokenEmail
                }
            }
        }
        
        register(user: user)
    }
    
    public func logout() {
        user = nil
        storageService.deleteUser()
        userService.logout()
    }
}

@available(iOS 13.0, *)
extension MyAccountViewModel: ASAuthorizationControllerDelegate {
    
    @available(iOS 13.0, *)
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            
            // Create an account in your system.
            let userIdentifier = appleIDCredential.user
            let authCode = appleIDCredential.authorizationCode
            let idenToken = appleIDCredential.identityToken
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
        
            CLog.print(.debug, .myAccount, "Apple sign in - \(userIdentifier)")
            CLog.print(.debug, .myAccount, "Apple sign in - \(fullName?.familyName ?? "none")")
            CLog.print(.debug, .myAccount, "Apple sign in - \(fullName?.givenName ?? "none")")
            CLog.print(.debug, .myAccount, "Apple sign in - \(email ?? "none")")
            
            registerWith(uid: userIdentifier,
                                   authCode: authCode,
                                   idenToken: idenToken,
                                   givenName: fullName?.givenName,
                                   familyName: fullName?.familyName,
                                   email: email)
            
        // For the purpose of this demo app, store the `userIdentifier` in the keychain.
        //            self.saveUserInKeychain(userIdentifier)
        default:
            break
        }
    }
    
    @available(iOS 13.0, *)
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        CLog.print(.error, .myAccount, "Error - \(error.localizedDescription)")
        output?.presentAlert(by: .failedAppleRegistration(error))
    }
}


