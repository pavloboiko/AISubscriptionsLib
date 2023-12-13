//
//  GeneralManagerProtocol.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/17/21.
//

import Foundation

public protocol AISubscriptionsManagerProtocol {
    var logLevel: LogLevel { get set }
    var requestMetric: AppMetricProtocol? { get set }
    var used: Bool { get }
    var products: [Product] { get }
    var purchases: [Purchase] { get }
    var attemptsCount: Int { get }
    var renewedAttemptsTime: Date? { get }
    var renewedAttemptsCount: Int { get }
    var bonusCount: Int { get }
    var bonusAttempts: Int { get }
    var bonusReloadTime: Date? { get }
    var consumables: [Consumable]? { get }
    var firstRegistredDate: Date? { get }
    var appInfo: AppInfoProtocol { get }
    
    func start()
    func start(inapps: [String]) // for test
    func getProducts(_ completion:@escaping SuccessResult)
    func getPurchase(_ completion:@escaping SuccessResult)
    func purchase(productID: String, onValidate: @escaping SuccessResult)
    func purchase(productID: String, onPurchase: SuccessResult?, onValidate: @escaping SuccessResult)
    func restore(onValidate: @escaping SuccessResult)
    func restore(onRestore: SuccessResult?, onValidate: @escaping SuccessResult)
    func getAttempts(_ completion: @escaping SuccessResult)
    func consume(_ completion: @escaping SuccessResult)
    func getBonus(_ completion: @escaping SuccessResult)
    func consumeBonus(_ completion: @escaping SuccessResult)
    func getConsumables(_ completion: @escaping SuccessResult)
    func consume(for productID: String, _ completion: @escaping SuccessResult)
    func consume(_ count: UInt, for productId: String, completion: @escaping SuccessResult)
    func isActive(by product_id: String) -> Bool
    func compareTimestamps(completion: @escaping SuccessResult)
    func cancelObserve()
    
    func migrate(user email: String, name: String?, _ completion: @escaping SuccessResult)
    
}


