//
//  DeviceService.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/2/21.
//

import Foundation
import UIKit

protocol DeviceServiceProtocol {
    
    func register()
    var firstRegistredDate: Date? { get }

}

class DeviceService: DeviceServiceProtocol {
    
    let apiManager: APIServiceProtocol
    var storage: StorageServiceProtocol

    var firstRegistredDate: Date?
    
    init(apiManager: APIServiceProtocol, storage: StorageServiceProtocol) {
        self.apiManager = apiManager
        self.storage = storage
    }
    
    private func generateDeviceID() -> DeviceID {
        let uuid = UUID().uuidString
        return DeviceID(key: uuid)
    }
    
    func register() {
        CLog.print(.info, .device, "API Server - ", API.signInDevice.baseURL)
        if let deviceID = storage.deviceID, deviceID.sync {
            CLog.print(.info, .device, "Saved in keychain - \(deviceID)")
            self.registerDeviceID(deviceID.key) { (result) in
                if case .success(let success) = result, success {
                    CLog.print(.description, .device, "Device On Server was updated")
                } else {
                    CLog.print(.description, .device, "Device On Server Not updated")
                }
            }
        } else {
            var deviceID = storage.deviceID ?? generateDeviceID()
            checkDeviceID(deviceID.key) { [weak self] (success, id) in
                if success {
                    if let newID = id {
                        deviceID.key = newID
                    }
                    self?.registerDeviceID(deviceID.key) { (result) in
                        if case .success(let success) = result, success {
                            guard let self = self else { return }
                            deviceID.sync = true
                            self.storage.deviceID = deviceID
                            CLog.print(.description, .device, "Registred in keychain - \(self.storage.deviceID?.key ?? "none")")
                        } else {
                            CLog.print(.description, .device, "Not registred device id")
                        }
                    }
                }
            }
        }
    }
    
    func checkDeviceID(_ deviceID: String, completion: @escaping ((Bool, String?)->())) {
        let params: [String: Any] = [ "id_to_check": deviceID ]
    
        apiManager.sendSigned(api: .checkDeviceID, with: params) { (result) in
            switch result {
            case .failure(let error):
                CLog.print(.description, .device, "ERROR :", error.localizedDescription)
                CLog.print(.error, .device, "response: ", result)
                completion(false, nil)
            case .success(let jsonDictionary):
                CLog.print(.description, .device, "RESPONSE DATA - ", jsonDictionary)

                if let newDeviceID = jsonDictionary["next_uniq"] as? String {
                    completion(true, newDeviceID)
                } else {
                    completion(false, nil)
                }
            }
        }
    }
    
    func registerDeviceID(_ deviceID: String, completion: @escaping SuccessResult) {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            completion(.failure(.badParameters))
            return
        }
        var params: [String: Any] = [
            "device_id": deviceID,
            "ios_version": UIDevice.current.systemVersion,
            "bundle_id": bundleID
        ]
        
        if let value = Locale.current.languageCode {
            params["locale"] = value
        }
       
        if var model = modelIdentifier() {
            #if DEBUG
            #if targetEnvironment(simulator)
            model = model + " Simulator"
            #else
            model = model + " Debug"
            #endif
            #endif

            params["device_model"] = model
        }
        
        CLog.print(.info, .device, "Register device \(params)")
        CLog.print(.debug, .device, "\n----------\n\n https://subs.attributetechs.com/admin/subs2/iosdevice/?q=\(deviceID)  \n\n----------\n ")
        
        apiManager.sendSigned(api: .signInDevice, with: params) { [weak self] (result) in
            switch result {
            case .failure(let error):
                CLog.print(.error, .device, "API ERROR :", error.localizedDescription)
                completion(.failure(error))
            case .success(let jsonDictionary):
                CLog.print(.description, .device, "RESPONSE DATA - ", jsonDictionary)
                if let jsonData = jsonDictionary["data"] as? [String: Any],
                   let registerInterval = jsonData["first_registered_ms"] as? Double {
                    self?.firstRegistredDate = registerInterval.dateFrom1970Ms
                }
                completion(.success(true))
            }
        }
    }
    
    func modelIdentifier() -> String? {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
}

