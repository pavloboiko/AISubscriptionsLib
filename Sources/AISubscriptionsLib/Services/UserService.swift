//
//  UserService.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/1/21.
//

import Foundation
import UIKit
import AuthenticationServices

protocol UserServiceProtocol {
    func register()
    func register(user: User, confirmation: Bool, completion: SuccessResult?)
    func logout()
    func deleteUser(confirmation: Bool, completion: SuccessResult?)
    @available(iOS 13.0, *)
    func checkCredential(by userID: String, completion: SuccessResult?)
}

class UserService: UserServiceProtocol {
    
    let apiManager: APIServiceProtocol
    var storage: StorageServiceProtocol
    
    init(apiManager: APIServiceProtocol, storage: StorageServiceProtocol) {
        self.apiManager = apiManager
        self.storage = storage
    }
    
    func register() {
        guard let user = storage.user else {
            CLog.print(.error, .user, "User not found in Keychain")
            return
        }
        register(user: user, confirmation: false) { (result) in
            if case .success(let success) = result, success {
                CLog.print(.description, .user, "User was updated")
            } else {
                CLog.print(.description, .user, "User was error updated")
            }
        }
    }
    
    func register(user: User, confirmation: Bool, completion: SuccessResult?) {
        guard let bundleID = Bundle.main.bundleIdentifier, let deviceID = storage.deviceID?.key else {
            completion?(.failure(.badParameters))
            return
        }
        var params: [String: Any] = [
            "device_id": deviceID,
            "bundle_id": bundleID
        ]
        
        switch user.source {
        case .sev:
            if let value = user.email {
                params["user_id"] = value
                params["email"] = value
            }
            if let value = user.name {
                params["profile_name"] = value
            }
            
            params["send_confirmation"] = confirmation ? 1 : 0
    
        case .siwa:
            
            if let value = user.authCode {
                params["auth_code"] = value
            }
            
        default:
            break
        }
        
        params["signin_source"] = user.source.rawValue
        
        apiManager.sendSigned(api: .signInUser, with: params)  { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                CLog.print(.error, .user, "[\(API.signInUser)] API ERROR :", error.localizedDescription)
                completion?(.failure(error))
            case .success(let jsonDictionary):
                CLog.print(.description, .user, "[\(API.signInUser)] RESPONSE DATA - ", jsonDictionary)
                if user.source == .sev {
                    var refreshUser = user
                    if let data = jsonDictionary["data"] as? [String: Any] {
                       if let isVerified = data["email_verified"] as? Bool {
                           refreshUser.isVerified = isVerified
                           
                           if !isVerified,
                                let isExpiredMs = data["before_expiration_ms"] as? Double {
                               refreshUser.confirmationCodeIsValid = isExpiredMs > 0
                           }
                       }
                    }
                    self.storage.user = refreshUser
                } else {
                    self.storage.user = user
                }
                completion?(.success(true))
            }
        }
    }
    
    func deleteUser(confirmation: Bool, completion: SuccessResult?) {
        guard let deviceID = storage.deviceID?.key else {
            completion?(.failure(.badParameters))
            return
        }
        var params: [String: Any] = [
            "dev_id": deviceID
        ]
        
        apiManager.sendSigned(api: .deleteUser, with: params)  { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                CLog.print(.error, .user, "[\(API.deleteUser)] API ERROR :", error.localizedDescription)
                completion?(.failure(error))
            case .success(let jsonDictionary):
                CLog.print(.description, .user, "[\(API.deleteUser)] RESPONSE DATA - ", jsonDictionary)
                completion?(.success(true))
            }
        }
    }
    
    func logout() {
        guard let bundleID = Bundle.main.bundleIdentifier, let deviceID = storage.deviceID?.key else { return }
        let params: [String: Any] = [
            "device_id": deviceID,
            "bundle_id": bundleID
        ]
        apiManager.sendSigned(api: .logout, with: params)  { (result) in
            switch result {
            case .failure(let error):
                CLog.print(.error, .user, "[\(API.logout)] API ERROR :", error.localizedDescription)
            case .success(let jsonDictionary):
                CLog.print(.description, .user, "[\(API.logout)] RESPONSE DATA - ", jsonDictionary)
            }
        }
    }
    
    @available(iOS 13.0, *)
    func checkCredential(by userID: String, completion: SuccessResult? = nil) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        appleIDProvider.getCredentialState(forUserID: userID) { [weak self] (credentialState, error) in
            guard let self = self else { return }
            switch credentialState {
            case .authorized:
                CLog.print(.description, .user, "[AppleAuthorize] Credential authorize with siwa")
                completion?(.success(true))
                break // The Apple ID credential is valid.
            case .revoked, .notFound:
                CLog.print(.description, .user, "[AppleAuthorize] Credential with siwa Revoke or notFound")
                // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                self.storage.deleteUser()
                self.logout()
                completion?(.failure(.expired))
                break
            default:
                completion?(.failure(.other))
                break
            }
        }
    }
  
}
