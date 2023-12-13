//
//  ConsumableService.swift
//  PurchaseClientDemo
//
//  Created by Serjant Alexandru on 02.07.2021.
//

import Foundation

protocol ConsumableServiceProtocol {

    var consumables: [Consumable]? { get }
    
    func request(_ completion: SuccessResult?)
    func consume(for productId: String, completion: SuccessResult?)
    func consume(_ count: UInt, for productId: String, completion: SuccessResult?)
}

class ConsumableService: ConsumableServiceProtocol {

    private var apiService: APIServiceProtocol
    private var storage: StorageServiceProtocol

    var consumables: [Consumable]?
    
    var params: [String: Any]? {
        get {
            guard let bundleID = Bundle.main.bundleIdentifier, let deviceID = storage.deviceID?.key else { return nil }
            return [
                "device_id": deviceID,
                "bundle_id": bundleID
            ]
        }
    }
    
    init(apiService: APIServiceProtocol, storage: StorageServiceProtocol) {
        self.apiService = apiService
        self.storage = storage
    }
    
    func request(_ completion: SuccessResult?) {
        guard let params = params else {
            completion?(.failure(.badParameters))
            return
        }

        apiService.sendSigned(api: .reqestConsumables, with: params) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(let apiError):
                CLog.print(.error, .bonus, "[\(API.requestAttempts.rawValue)] API error - \(apiError)")
                completion?(.failure(apiError))
            case .success(let jsonDictionary):
                if let data = jsonDictionary["data"] as? [String: Any],
                   let consumableAmounts = data["consumable_amounts"] as? [String: Int] {
                    let list: [Consumable] = consumableAmounts.map { Consumable(productId: $0.key, amount: $0.value) }
                    self.consumables = list
                    completion?(.success(true))
                }
            }
        }
    }
    
    func consume(for productId: String, completion: SuccessResult?) {
        consume(1, for: productId, completion: completion)
    }
    
    func consume(_ count: UInt = 1, for productId: String, completion: SuccessResult?) {
        guard var params = params else {
            completion?(.failure(.badParameters))
            return
        }
        params["product_id"] = productId
        params["amount_to_consume"] = count
        
        apiService.sendSigned(api: .consumeConsumables, with: params) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(let apiError):
                CLog.print(.error, .bonus, "[\(API.requestAttempts.rawValue)] API error - \(apiError)")
                if case .emptyConsumableAttempts = apiError {
                    self.updateConsumable(Consumable(productId: productId, amount: 0))
                }
                completion?(.failure(apiError))
            case .success(let jsonDictionary):
                if let data = jsonDictionary["data"] as? [String: Any],
                   let amounts = data["amounts_left"] as? Int {
                    self.updateConsumable(Consumable(productId: productId, amount: amounts))
                    completion?(.success(true))
                }
            }
        }
    }
    
    func updateConsumable(_ consumable: Consumable) {
        if let idx = self.consumables?.firstIndex(where: { $0.productId == consumable.productId }) {
            self.consumables?[idx] = consumable
        } else {
            self.consumables?.append(consumable)
        }
    }
    
}
