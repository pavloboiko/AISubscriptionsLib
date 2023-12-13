//
//  AppInfoService.swift
//  PurchaseClientDemo
//
//  Created by Serjant Alexandru on 3/16/21.
//

import Foundation

public protocol AppInfoProtocol {
    
    var isReady: Bool { get }
    var productIDs: [String] { get }
    var eula: URL? { get }
    var privacyPolicy: URL? { get }
    var confirmationEmail: String? { get }

}

protocol AppInfoServiceProtocol {
    
    func retreive(completion: SuccessResult?)
    func retreiveProductIds(completion: SuccessResult?)
    
}

final class AppInfoService: AppInfoProtocol, AppInfoServiceProtocol {

    let apiService: APIServiceProtocol
    var storage: StorageServiceProtocol
    
    var update = true
    
    var isReady: Bool {
        if storage.productIDs == nil {
            retreive(completion: nil)
            return false
        }
        if update {
            retreive(completion: nil)
        }
        return true
        
    }
    
    var productIDs: [String] {
        storage.productIDs ?? []
    }
    
    var eula: URL? {
        guard let link = storage.eulaLink else { return nil }
        return URL(string: link)
    }
    
    var privacyPolicy: URL? {
        guard let link = storage.privacyPolicyLink else { return nil }
        return URL(string: link)
    }
    
    var confirmationEmail: String? {
        storage.confirmationEmail
    }

    init(apiService: APIServiceProtocol, storage: StorageServiceProtocol) {
        self.apiService = apiService
        self.storage = storage
    }
        
    func retreive(completion: SuccessResult?) {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            completion?(.failure(.badParameters))
            return
        }
        let params: [String: Any] = [
            "bundle_id": bundleID
        ]
        apiService.sendSigned(api: .appInfo, with: params) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(let apiError):
                CLog.print(.error, .info, "[\(API.appInfo.rawValue)] API error - \(apiError)")
                completion?(.failure(apiError))
            case .success(let jsonDictionary):
                CLog.print(.description, .info, "[\(API.appInfo.rawValue)] RESPONSE DATA - ", jsonDictionary)
                if let attemptsDictionary = jsonDictionary["data"] as? [String: Any] {
                    self.update = false
                    if let eulaLink = attemptsDictionary["eula_url"] as? String {
                        self.storage.eulaLink = eulaLink
                    }
                    if let ppLink = attemptsDictionary["privacy_policy_url"] as? String {
                        self.storage.privacyPolicyLink = ppLink
                    }
                    if let email = attemptsDictionary["confirmation_email"] as? String {
                        self.storage.confirmationEmail = email
                    }
                    
                    if let products = attemptsDictionary["products"] as? [[String: Any]] {
                        let productIDs = products.compactMap { $0["product_id"] as? String }
                        self.storage.productIDs = productIDs
                        completion?(.success(true))
                    } else {
                        completion?(.failure(.badResult))
                    }
                } else {
                    completion?(.failure(.badResult))
                }
            }
        }
    }
    
    func retreiveProductIds(completion: SuccessResult?) {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            completion?(.failure(.badParameters))
            return
        }
        let params: [String: Any] = [
            "bundle_id": bundleID
        ]
        apiService.send(url: API.productIds.url, with: params) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(let apiError):
                CLog.print(.error, .info, "[\(API.productIds.rawValue)] API error - \(apiError)")
                completion?(.failure(apiError))
            case .success(let jsonDictionary):
                CLog.print(.description, .info, "[\(API.productIds.rawValue)] RESPONSE DATA - ", jsonDictionary)
                if let attemptsDictionary = jsonDictionary["data"] as? [String: Any] {
                    if let productIDs = attemptsDictionary["product_ids"] as? [String] {
                        self.storage.productIDs = productIDs
                        completion?(.success(true))
                    } else {
                        completion?(.failure(.badResult))
                    }
                } else {
                    completion?(.failure(.badResult))
                }
            }
            
        }
    }
}

