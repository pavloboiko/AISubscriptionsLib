//
//  MigrationService.swift
//  PurchaseClientDemo
//
//  Created by Serjant Alexandru on 3/22/21.
//

import Foundation

protocol MigrationServiceProtocol {
    
    func user(email: String, name: String?, completion: SuccessResult?)
    
}

class MigrationService: MigrationServiceProtocol {

    private var apiService: APIServiceProtocol
    private var storage: StorageServiceProtocol
 
    init(apiService: APIServiceProtocol, storage: StorageServiceProtocol) {
        self.apiService = apiService
        self.storage = storage
    }
    
    func user(email: String, name: String?, completion: SuccessResult? = nil) {
        guard !storage.isUserMigrated else {
            completion?(.success(false))
            return
        }
        guard let bundleID = Bundle.main.bundleIdentifier, let deviceID = storage.deviceID?.key else {
            completion?(.failure(.badParameters))
            return
        }
        var params: [String: Any] = [
            "device_id": deviceID,
            "bundle_id": bundleID,
            "email": email
        ]
        
        if let value = name {
            params["name"] = value
        }
        
        apiService.sendSigned(api: .migrate, with: params) { [weak self] (result) in
            switch result {
            case .failure(let error):
                CLog.print(.error, .migration, "[\(API.migrate)] API ERROR :", error.localizedDescription)
                completion?(.failure(error))
            case .success(let jsonDictionary):
                CLog.print(.info, .migration, "[\(API.migrate)] RESPONSE DATA - ", jsonDictionary)
                completion?(.success(true))
                self?.storage.isUserMigrated = true
            }
        }
        
    }
    
}
