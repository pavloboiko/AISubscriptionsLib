//
//  GeneralManager.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/2/21.
//

import Foundation
import SwiftyStoreKit
import StoreKit


public class AISubscriptionsManager {
                
    private let services: ServicesContainer
    
    public init() {
        services = ServicesContainer.builder()
    }
    
    deinit {
        removeObservers()
    }

    func checkReady(_ completion: @escaping (()->Void)) {
        if services.appInfo.isReady {
            completion()
        } else {
            services.appInfo.retreiveProductIds { (result) in
                if case .success = result {
                    completion()
                }
            }
        }
    }
    
    public func start() {
        
        services.device.register()
     
        checkReady { [weak self] in
            guard let self = self else { return }
            self.start(inapps: self.services.appInfo.productIDs)
        }
        
        addObservers()
        
    }
    
    public func start(inapps: [String]) {
        services.purchase.setup(inapps: inapps)
        services.purchase.retreiveProducts()
    }

    func updateServerData() {
        
        updatePurchases()
        updateAttempts()
      
    }
    
    func updatePurchases() {
        services.purchase.getPurchase(nil)
    }
    
    func updateAttempts() {
        services.bonus.requestAttempts { _ in }
    }
    
}

extension AISubscriptionsManager {
    
    func addObservers() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        
    }
   
    public func removeObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }
    
    @objc
    func applicationDidBecomeActive() {
        checkReady { [weak self] in
            guard let self = self else { return }
            self.updateServerData()
        }
    }
  
}

extension AISubscriptionsManager: AISubscriptionsManagerProtocol {
    
    public var used: Bool {
        services.storage.deviceID != nil
    }
    
    public var logLevel: LogLevel {
        get {
            CLog.shared.level
        }
        set {
            CLog.shared.level = newValue    
        }
    }
    
    public var requestMetric: AppMetricProtocol? {
        get {
            CLog.shared.metric
        }
        set {
            CLog.shared.metric = newValue
        }
    }
    
    public var appInfo: AppInfoProtocol {
        services.appInfo
    }
    
    public var firstRegistredDate: Date? {
        services.device.firstRegistredDate
    }
    
    public var products: [Product] {
        services.purchase.products
    }
    
    public var purchases: [Purchase] {
        services.purchase.purchases
    }
    
    public var attemptsCount: Int {
        services.bonus.attemptsCount
    }
    
    public var renewedAttemptsTime: Date? {
        services.bonus.renewedAttemptsTime
    }
    
    public var renewedAttemptsCount: Int {
        services.bonus.renewedAttemptsCount
    }
    
    public var bonusCount: Int {
        services.bonus.bonusCount
    }
    
    public var bonusAttempts: Int {
        services.bonus.bonusAttemptsCount
    }
    
    public var bonusReloadTime: Date? {
        services.bonus.bonusUpdateTime
    }
    
    public var consumables: [Consumable]? {
        services.consumables.consumables
    }
    
    public func getProducts(_ completion: @escaping SuccessResult) {
        services.purchase.retreiveProducts(completion)
    }
    
    public func getPurchase(_ completion: @escaping SuccessResult) {
        services.purchase.getPurchase(completion)
    }
    
    public func purchase(productID: String, onValidate: @escaping SuccessResult) {
        purchase(productID: productID) { (result) in
            if case .failure = result {
                onValidate(result)
            }
        } onValidate: { (result) in
            onValidate(result)
        }
    }
    
    public func purchase(productID: String, onPurchase: SuccessResult? = nil, onValidate: @escaping SuccessResult) {
        services.purchase.resetClosures()
        services.purchase.purchaseResponse = onPurchase
        services.purchase.receipteResponse = onValidate
        services.purchase.makePurchase(by: productID)
    }

    public func restore(onValidate: @escaping SuccessResult) {
        restore { (result) in
            if case .failure = result {
                onValidate(result)
            }
        } onValidate: { (result) in
            onValidate(result)
        }
    }

    public func restore(onRestore: SuccessResult?, onValidate: @escaping SuccessResult) {
        services.purchase.resetClosures()
        services.purchase.restoreResponse = onRestore
        services.purchase.receipteResponse = onValidate
        services.purchase.restorePurchase()
    }
    
    public func getAttempts(_ completion: @escaping SuccessResult) {
        services.bonus.requestAttempts(completion)
    }
    
    public func consume(_ completion: @escaping SuccessResult) {
        services.bonus.consumeAttempts(completion)
    }
    
    public func getBonus(_ completion: @escaping SuccessResult) {
        services.bonus.requestBonus(completion)
    }
    
    public func consumeBonus(_ completion: @escaping SuccessResult) {
        services.bonus.consumeBonus(completion)
    }
    
    public func getConsumables(_ completion: @escaping SuccessResult) {
        services.consumables.request(completion)
    }
    
    public func consume(for productId: String, _ completion: @escaping SuccessResult) {
        services.consumables.consume(for: productId, completion: completion)
    }
    
    public func consume(_ count: UInt, for productId: String, completion: @escaping SuccessResult) {
        services.consumables.consume(count, for: productId, completion: completion)
    }
    
    public func isActive(by productID: String) -> Bool {
        services.purchase.purchases.first { $0.productID == productID }?.expiresDateMs ?? 0 > Timestamp.now()
    }
    
    public func migrate(user email: String, name: String?, _ completion: @escaping SuccessResult) {
        services.migrate.user(email: email, name: name, completion: completion)
    }
    
    public func compareTimestamps(completion: @escaping SuccessResult) {
        services.apiManager.compareTimestamps { err in
            if let nsError = err as NSError? {
                if nsError.code == 1 {
                    completion(.failure(.invalidTimestamps))
                } else {
                    completion(.failure(.custom(nsError)))
                }
            }else {
                completion(.success(true))
            }
        }
    }
    
    public func cancelObserve() {
        removeObservers()
    }
}


