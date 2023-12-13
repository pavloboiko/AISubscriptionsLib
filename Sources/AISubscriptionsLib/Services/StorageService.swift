//
//  DeviceID.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 1/20/21.
//

import Foundation
import KeychainSwift

protocol StorageServiceProtocol {
    
    var deviceID: DeviceID? { get set }
    var user: User? { get set }
    var isPurchased: Bool { get set }
    var purchases: [Purchase]? { get set }
    var attemptCount: Int { get set }
    var attemptUpdateDate: Date? { get set }
    func deleteDeviceID()
    func deleteUser()
    var isUserMigrated: Bool { get set }
    
    var productIDs: [String]? { get set }
    var eulaLink: String? { get set }
    var privacyPolicyLink: String? { get set }
    var confirmationEmail: String? { get set }
}

final class StorageService: StorageServiceProtocol {
    
    private let device_key = "storage.device_id"
    private let user_key = "strorage.user"
    private let purchase_key = "storage.is_purchase"
    private let user_migrated_key = "storage.user_migrated_key"
    private let purchases_list_key = "storage.is_purchases_list_key"
    
    private let kvs_key = "storage.kvs_key"
    private let attempts_key = "storage.attempts_count"
    private let attempts_update_key = "storage.attempts_count"
    
    private let product_ids_key = "storage.product_ids_key"
    private let eula_key = "storage.eula_key"
    private let privacy_policy_key = "storage.privacy_policy_key"
    private let confirmation_email_key = "storage.confirmation_email_key"

    private let keychain = KeychainSwift()
    private let kvsStore = NSUbiquitousKeyValueStore()
    
    // MARK:- Device ID
    
    var deviceID: DeviceID? {
        get {
            if let deviceData = keychain.getData(device_key) {
                let decoder = JSONDecoder()
                if let loadedDeviceID = try? decoder.decode(DeviceID.self, from: deviceData) {
                    return loadedDeviceID
                }
            }
            return nil
        }
        
        set {
            guard let value = newValue else { return }
            
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(value) {
                keychain.set(encoded, forKey: device_key)
            }
        }
    }
    
    func deleteDeviceID() {
        keychain.delete(device_key)
    }
    
    // MARK:- User
    
    var user: User? {
        get {
            if let savedUser = keychain.getData(user_key) {
                let decoder = JSONDecoder()
                if let loadedUser = try? decoder.decode(User.self, from: savedUser) {
                    return loadedUser
                }
            }
            return nil
        }
        
        set {
            guard let value = newValue else { return }
            
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(value) {
                CLog.print(.debug, .storage, "save user - \(value)")
                keychain.set(encoded, forKey: user_key)
            }
        }
    }
    
    func deleteUser() {
        keychain.delete(user_key)
    }
    
    var isUserMigrated: Bool {
        get { keychain.getBool(user_migrated_key) ?? false }
        set { keychain.set(newValue, forKey: user_migrated_key) }
    }
    
    // MARK:- AppInfo
    
    var productIDs: [String]? {
        get { UserDefaults.standard.array(forKey: product_ids_key) as? [String] }
        set { UserDefaults.standard.set(newValue, forKey: product_ids_key) }
    }
    
    var eulaLink: String? {
        get { UserDefaults.standard.string(forKey: eula_key) }
        set { UserDefaults.standard.set(newValue, forKey: eula_key) }
    }
    
    var privacyPolicyLink: String? {
        get { UserDefaults.standard.string(forKey: privacy_policy_key) }
        set { UserDefaults.standard.set(newValue, forKey: privacy_policy_key) }
    }
    
    var confirmationEmail: String? {
        get { UserDefaults.standard.string(forKey: confirmation_email_key) }
        set { UserDefaults.standard.set(newValue, forKey: confirmation_email_key) }
    }
    
    // MARK:- Purchase
    
    var isPurchased: Bool {
        get { keychain.getBool(purchase_key) ?? false }
        set { keychain.set(newValue, forKey: purchase_key) }
    }
        
    var purchases: [Purchase]? {
        get {
            guard let data = UserDefaults.standard.data(forKey: purchases_list_key),
                  let array = try? PropertyListDecoder().decode([Purchase].self, from: data) else { return nil }
            return array
        }
        set {
            guard let value = newValue,
                  let data = try? PropertyListEncoder().encode(value) else { return }
            UserDefaults.standard.set(data, forKey: purchases_list_key)
            UserDefaults.standard.synchronize()
        }
    }
    
    //MARK:- Bonus
    
    var attemptCount: Int {
        get {
            if let strValue = keychain.get(attempts_key),
               let intValue = Int(strValue) {
                return intValue
            }
            return 0
        }
        set {
            keychain.set(String(newValue), forKey: attempts_key)
        }
    }
    
    var attemptUpdateDate: Date? {
        get {
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            formatter.dateStyle = .medium
            if let strValue = keychain.get(attempts_update_key),
               let dateValue = formatter.date(from: strValue) {
                return dateValue
            }
            return nil
        }
        set {
            guard let value = newValue else { return }
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            formatter.dateStyle = .medium
            keychain.set(formatter.string(from: value), forKey: attempts_update_key)
        }
    }
    
    // MARK:- Key-Value Stroage (KVS)
    
    func saveToKVS(id: String) {
        kvsStore.set(id, forKey: kvs_key)
        kvsStore.synchronize()
        CLog.print(.debug, .storage, "Stored new KVS \(id)")
    }
    
    var kvs_id: String? {
        kvsStore.synchronize()
        guard let storedUserName = kvsStore.string(forKey: kvs_key) else {
            return nil
        }
        CLog.print(.debug, .storage, "Get saved KVS \(storedUserName)")
        
        return storedUserName
    }
    
    func clear_kvs() {
        kvsStore.removeObject(forKey: kvs_key)
    }
 
}



