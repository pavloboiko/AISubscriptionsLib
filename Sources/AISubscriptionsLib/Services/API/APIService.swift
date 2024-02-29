//
//  APIService.swift
//  PurchaseClient
//
//  Created by iMac on 09.09.2020.
//

import UIKit
import SwiftyStoreKit
import CommonCrypto
import AuthenticationServices
import StoreKit

typealias ServerResult = Result<[String: Any], APIError>
typealias ServerResponse = (ServerResult)->Void

enum API: String, CaseIterable {
    case signature = "?signature="
    case testSignature = "test_signed/"
    case testAPI = "test_api"
    case verifyReceipt = "ios_verify_receipt"
    case signInDevice = "ios_device_signin/"
    case checkDeviceID = "ios_check_device_id_uniqueness/"
    case signInUser = "ios_user_signin/"
    case deleteUser = "ios_delete_user/"
    case requestAttempts = "ios_request_free_attempt/"
    case consumeAttempts = "ios_consume_free_attempt/"
    case requestBonus = "ios_request_bonus_cycle/"
    case consumeBonus = "ios_consume_bonus_cycle/"
    case getPurchases = "ios_get_user_purchases/"
    case appInfo = "app_info"
    case productIds = "ios_application_product_id_list"
    case logout = "ios_user_logout"
    case migrate = "ios_panda_user_transfer_login/"
    case reqestConsumables = "ios_get_consumable_amounts/"
    case consumeConsumables = "ios_consume_product/"
      
    var baseURL: String {
//        #if DEBUG
//        return "https://datacomapps2-dev.azurewebsites.net/"
//        #endif
        return "https://datacomapps2.azurewebsites.net/"
    }
    
    var url: URL {
        guard let url = URL(string: baseURL + self.rawValue) else
        { return URL(string: "google.com")! }
        return url
    }
    
    var urlString: String {
        return baseURL + self.rawValue
    }
    
    func signedUrl(with hash: String) -> URL? {
        let string = baseURL + self.rawValue + API.signature.rawValue + hash
        guard let url = URL(string: string) else { return nil }
        return url
    }
    
    static func api(from url: URL) -> API? {
        let api = API.allCases.first { url.absoluteString.dropFirst($0.baseURL.count).hasPrefix($0.rawValue) }
        return api
    }
    
}

protocol APIServiceProtocol {
    func sendSigned(api: API, with params: [String: Any], completion: @escaping ServerResponse)
    func send(url: URL, with params: [String: Any], completion: @escaping ServerResponse)
    func compareTimestamps(completion: @escaping (Error?) -> Void)
}


class APIService {
    
    let storage: StorageServiceProtocol
    let networking = Networking()
    let reachability = try! Reachability()
  
    var isConnectedToNetwork: Bool {
        reachability.connection != .unavailable
    }
    
    init(storage: StorageServiceProtocol) {
        self.storage = storage
        initReachability()
    }
  
}

extension APIService {
    
    private func hmacURL(for api: API, with params: [String: Any]) -> URL? {
        guard let hash = HMACHelper.hash(from: params) else { return nil }
        guard let url = api.signedUrl(with: hash) else { return nil }
        return url
    }
    
}

extension APIService {
    
    func initReachability() {
        reachability.whenReachable = { reachability in
            CLog.print(.info, .api, "Connection - Reachability - \(reachability.connection) ")
            if reachability.connection == .wifi {
                CLog.print(.debug, .api, "Connection - Reachable via WiFi")
            } else {
                CLog.print(.debug, .api, "Connection - Reachable via Cellular")
            }
        }
        reachability.whenUnreachable = { reachability in
            CLog.print(.debug, .api, "Connection - Not reachable")
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            CLog.print(.error, .api, "Unable to start notifier")
        }
    }
    
  
    
}

extension APIService: APIServiceProtocol {
    
    func sendSigned(api: API, with params: [String: Any], completion: @escaping ServerResponse) {

        var fullParams = params
        fullParams["timestamp"] = Timestamp.now()
        
        guard let url = hmacURL(for: api, with: fullParams) else {
            completion(.failure(.other))
            return
        }
        CLog.print(.debug, .api, "Request \(api.rawValue)")
        send(url: url, with: fullParams, completion: completion)
    }
    
    func send(url: URL, with params: [String: Any], completion: @escaping ServerResponse) {
        send(url: url, with: params, isRepeat: false, completion: completion)
    }
    
    func send(url: URL, with params: [String: Any], isRepeat: Bool = false, completion: @escaping ServerResponse) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: params, options: []) else { return completion(.failure(.other)) }
        
        guard isConnectedToNetwork else { return completion(.failure(.noConnection)) }
        
        networking.sendPostRequest(to: url, body: jsonData) { [weak self] response in
            switch response {
            case .failure(let error):
                 if (error as NSError).code == 500 {
                     CLog.print(.error, .api, "Error - 500 \(API.api(from: url)?.rawValue ?? "") - isRepeat \(isRepeat) - ", error.localizedDescription)
                     if isRepeat {
                         completion(.failure(.badResponse500))
                     } else {
                         self?.send(url: url, with: params, isRepeat: true, completion: completion)
                     }
                     return
                }
                CLog.print(.error, .api, "Error \(API.api(from: url)?.rawValue ?? "") while response", error.localizedDescription)
                completion(.failure(.response))
            case .success(let json):
                CLog.print(.debug, .api, "Response Success: \(API.api(from: url)?.rawValue ?? "") - isRepeat \(isRepeat) - ", json)
                
                if let jsonDictionary = json as? Dictionary<String, Any> {
                    CLog.print(.description, .api, "Response Status - ", jsonDictionary["status"] ?? "")
                    CLog.print(.debug, .api, "Response data - ", jsonDictionary)
                    let apiError = APIError.error(by: jsonDictionary["code"] as? String)
                    if case .none = apiError {
                        completion(.success(jsonDictionary))
                    } else {
                        completion(.failure(apiError))
                    }
                } else {
                    completion(.failure(.other))
                }
            }
        }
    }
}

// MARK: Universal
extension APIService {
    
    private func sendSigned(data: Any, completion: SuccessResult? = nil) {
        let params: [String: Any] = [ "data": data ]
    
        sendSigned(api: .testSignature, with: params) { (result) in
            switch result {
            case .failure(let error):
                CLog.print(.error, .api, "Response error", error.localizedDescription)
                CLog.print(.debug, .api, "response: ", result)
            case .success(let jsonDictionary):
                CLog.print(.debug, .api, "Response data - ", jsonDictionary)

            }
        }
    }
}

extension APIService {
    
    func compareTimestamps(completion: @escaping (Error?) -> Void) {
        
        let defaultError = NSError(domain: "Comparing timestamps error", code: 1)
        guard let components = URLComponents(string: "https://datacomprojects2.com/current_time"),
              let url = components.url else {
            completion(defaultError)
            return
        }
        
        let currentTimestamp = Timestamp.now()
        
        networking.sendPostRequest(to: url, body: Data()) { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let json):
                if let content = json as? [String: Any],
                   let serverTimestamp = Timestamp(content["time_ms"] as? String ?? "0") {
                    let interval = Timestamp(content["HMAC_TIME_DIFF_TOLERANCE_MS"] as? Double ?? 60*1000)
                    if fabs(serverTimestamp - currentTimestamp) > interval {
                        completion(defaultError)
                    } else {
                        completion(nil)
                    }
                } else {
                    let invalidResultError = NSError(domain: "Invalid result error", code: 1100)
                    completion(invalidResultError)
                }
            }
        }
    }
}


