//
//  Purchase.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/5/21.
//

import Foundation


public enum PurchaseStatus: String, Codable {
    case renewed, canceled
}

public enum ReceiptType: String, Codable {
    case Production, ProductionVPP, ProductionSandbox, ProductionVPPSandbox
}

public struct Purchase: Codable {
    
    public var productID: String
    public var type: PurchaseType = .renewable
    public var notificationStatus: PurchaseStatus
    public var receiptType: ReceiptType
    
    var originalPurchaseDateMs: Double
    var purchaseDateMs: Double
    var expiresDateMs: Double
    
    var originalTransactionID: String
    var transactionID: String
    var webOrderLineItemID: String
    var subscriptionGroupIdentifier: String
    
    public var isTrialPeriod: Int
    public var isIntroOfferPeriod: Int
    public var price: Double
    public var currency: String
    
    public var customIsPromotion: Int
    public var customPromoLevel: Int
    public  var customPromoType: Int
    
    init(_ dict: [String: Any]) {
        productID = dict["product_id"] as? String ?? ""
        if let purchaseTypeString = dict["purchase_type"] as? String {
            type = PurchaseType(rawValue: purchaseTypeString) ?? .renewable
        }
        purchaseDateMs = dict["purchase_date_ms"] as? Double ?? 0
        expiresDateMs = dict["expires_date_ms"] as? Double ?? 0
        price = 0
        currency = "USD"
        notificationStatus = .renewed
        originalTransactionID = dict["original_transaction_id"] as? String ?? "none"
        transactionID = dict["transaction_id"] as? String ?? "none"
        receiptType = .Production
        webOrderLineItemID = dict["web_order_line_item_id"] as? String ?? "none"
        subscriptionGroupIdentifier = dict["subscription_group_identifier"] as? String ?? "none"
        isTrialPeriod = dict["is_trial_period"] as? Int ?? 0
        originalPurchaseDateMs = dict["original_purchase_date_ms"] as? Double ?? 0
        isIntroOfferPeriod = dict["is_in_intro_offer_period"] as? Int ?? 0
        
        customIsPromotion = dict["custom_is_promotion"] as? Int ?? 0
        customPromoLevel = dict["custom_promo_level"] as? Int ?? 0
        customPromoType = dict["custom_promo_type"] as? Int ?? 0
    }
    
}

extension Purchase: Equatable { }

extension Purchase {
    func setPrice(for product: Product?) -> Purchase {
        guard let product = product else { return self }
        var purchase = self
        purchase.price = product.price.round(to: 2)
        purchase.currency = product.currencyCode
        return purchase
    }
}

extension Purchase {
    
    public var originalPurchaseDate: Date {
        originalPurchaseDateMs.dateFrom1970Ms
    }
    
    public var purchaseDate: Date {
        purchaseDateMs.dateFrom1970Ms
    }
    
    public var expiresDate: Date {
        expiresDateMs.dateFrom1970Ms
    }
    
    public var isSubscription: Bool {
        type == .renewable || type == .nonRenewable
    }
    
}
