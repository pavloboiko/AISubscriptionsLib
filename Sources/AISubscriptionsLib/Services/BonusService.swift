//
//  BonusService.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/8/21.
//

import Foundation

protocol BonusServiceProtocol {
    
    func requestAttempts(_ completion: SuccessResult?)
    func consumeAttempts(_ completion: SuccessResult?)
   
    var attemptsCount: Int { get }
    var renewedAttemptsTime: Date? { get }
    var renewedAttemptsCount: Int { get }
    
    func requestBonus(_ completion: SuccessResult?)
    func consumeBonus(_ completion: SuccessResult?)
    
    var bonusCount: Int { get }
    var bonusAttemptsCount: Int { get }
    var bonusUpdateTime: Date? { get }
    
}

class BonusService: BonusServiceProtocol {

    private var apiService: APIServiceProtocol
    private var storage: StorageServiceProtocol
    
    var params: [String: Any]? {
        get {
            guard let bundleID = Bundle.main.bundleIdentifier, let deviceID = storage.deviceID?.key else { return nil }
            return [
                "device_id": deviceID,
                "bundle_id": bundleID
            ]
        }
    }
    
    var attemptsCount: Int = 0
    var renewedAttemptsTime: Date?
    var renewedAttemptsCount: Int = 0

    var bonusCount: Int = 0
    var bonusAttemptsCount: Int = 0
    var bonusUpdateTime: Date?
    
    init(apiService: APIServiceProtocol, storage: StorageServiceProtocol) {
        self.apiService = apiService
        self.storage = storage
    }

    func requestAttempts(_ completion: SuccessResult? = nil) {
        guard let params = params else {
            completion?(.failure(.badParameters))
            return
        }
        apiService.sendSigned(api: .requestAttempts, with: params) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(let apiError):
                CLog.print(.error, .bonus, "[\(API.requestAttempts.rawValue)] API error - \(apiError)")
                completion?(.failure(apiError))
            case .success(let jsonDictionary):
                if let attemptsDictionary = jsonDictionary["data"] as? [String: Any] {
                    if let attempts = attemptsDictionary["remaining_attempts"] as? Int {
                        self.attemptsCount = attempts
                    }
                    if let updateInterval = attemptsDictionary["wait_for_ms"] as? Double {
                        self.renewedAttemptsTime = updateInterval.dateFromNowMs
                    }
                    if let attempts = attemptsDictionary["total_attempts"] as? Int {
                        self.renewedAttemptsCount = attempts
                    }
                    if let remaining = attemptsDictionary["remaining_cycles"] as? Int {
                        self.bonusCount = remaining
                    }
                    if let count = attemptsDictionary["attempts_for_cycle"] as? Int {
                        self.bonusAttemptsCount = count
                    }
                    completion?(.success(true))
                } else {
                    completion?(.failure(.badResult))
                }
            }
        }
    }
    
    func consumeAttempts(_ completion: SuccessResult? = nil) {
        guard let params = params else {
            completion?(.failure(.badParameters))
            return
        }
        apiService.sendSigned(api: .consumeAttempts, with: params) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(let apiError):
                CLog.print(.error, .bonus, "[\(API.consumeAttempts.rawValue)] API error - \(apiError)")
                completion?(.failure(apiError))
            case .success(let jsonDictionary):
                CLog.print(.description, .bonus, "[\(API.consumeAttempts.rawValue)] Succes - \(jsonDictionary)")
                if let attemptsDictionary = jsonDictionary["data"] as? [String: Any] {
                    if let attempts = attemptsDictionary["remaining_attempts"] as? Int {
                        self.attemptsCount = attempts
                    }
                    completion?(.success(true))
                } else {
                    completion?(.failure(.badResult))
                }
            }
        }
    }
    
    func requestBonus(_ completion: SuccessResult? = nil) {
        guard let params = params else {
            completion?(.failure(.badParameters))
            return
        }
        apiService.sendSigned(api: .requestBonus, with: params) { [unowned self] (result) in
            switch result {
            case .failure(let apiError):
                CLog.print(.error, .bonus, "[\(API.requestBonus.rawValue)] API error - \(apiError)")
                completion?(.failure(apiError))
            case .success(let jsonDictionary):
                CLog.print(.description, .bonus, "[\(API.requestBonus.rawValue)] Succes - \(jsonDictionary)")
                if let bonusDictionary = jsonDictionary["data"] as? [String: Any] {
                    if let attempts = bonusDictionary["remaining_attempts"] as? Int {
                        self.attemptsCount = attempts
                    }
                    if let updateInterval = bonusDictionary["wait_for_ms"] as? Double {
                        self.bonusUpdateTime = updateInterval.dateFromNowMs
                    }
                    if let remaining = bonusDictionary["remaining_cycles"] as? Int {
                        self.bonusCount = remaining
                    }
                    if let count = bonusDictionary["attempts_for_cycle"] as? Int {
                        self.bonusAttemptsCount = count
                    }
                    completion?(.success(true))
                } else {
                    completion?(.failure(.badResult))
                }
            }
        }
    }
    
    func consumeBonus(_ completion: SuccessResult? = nil) {
        guard let params = params else {
            completion?(.failure(.badParameters))
            return
        }
        apiService.sendSigned(api: .consumeBonus, with: params) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(let apiError):
                CLog.print(.error, .bonus,"[\(API.consumeBonus.rawValue)] API error - \(apiError)")
                completion?(.failure(apiError))
            case .success(let jsonDictionary):
                if let bonusDictionary = jsonDictionary["data"] as? [String: Any] {
                    if let attempts = bonusDictionary["remaining_attempts"] as? Int {
                        self.attemptsCount = attempts
                    }
                    if let remaining = bonusDictionary["remaining_cycles"] as? Int {
                        self.bonusCount = remaining
                    }
                    completion?(.success(true))
                } else {
                    completion?(.failure(.badResult))
                }
            }
        }
    }
    
}
    


