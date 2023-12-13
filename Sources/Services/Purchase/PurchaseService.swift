//
//  PurchaseManager.swift
//  PurchaseClient
//
//  Created by iMac on 09.09.2020.
//

import UIKit
import SwiftyStoreKit
import StoreKit

enum RestoreResult {
    case expired, purchased, notPurchased
}

typealias ReceiptResponse = ([Dictionary<String, Any>]?)->()

final class PurchaseService {

    var storage: StorageServiceProtocol

    var apiService: APIServiceProtocol
    
    public var purchaseResponse: SuccessResult? = nil
    public var restoreResponse: SuccessResult? = nil
    public var receipteResponse: SuccessResult? = nil
    
    
    init(apiService: APIServiceProtocol, storage: StorageServiceProtocol) {
        self.storage = storage
        self.apiService = apiService
        
        if let savedPurchases = storage.purchases {
            purchases = savedPurchases
        }
        completeTransactions()
        
        prepareStoreKit()
    }
     
    var allInapps = [String]()
    
    //Local check
    private(set) var isPurchased: Bool {
        get { storage.isPurchased }
        set { storage.isPurchased = newValue }
    }
    
    private(set) var products: [Product] = [] {
        didSet {
            CLog.print(.info, .purchase, "Product from server.", products)
        }
    }
    
    private(set) var purchases: [Purchase] = [] {
        didSet {
            CLog.print(.info, .purchase, "Purchases of device. \(storage.deviceID?.key ?? "none") > ", purchases)
        }
    }
    
    func prepareStoreKit() {
        SwiftyStoreKit.shouldAddStorePaymentHandler = { (payment, product) -> Bool in true }
    }
    
    func resetClosures() {
        purchaseResponse = nil
        restoreResponse = nil
        receipteResponse = nil
    }
}

//MARK: Called from start
extension PurchaseService {
    public func setup(inapps: [String] = []) {
        allInapps = inapps
    }
}

extension PurchaseService {
    func completeTransactions() {
        SwiftyStoreKit.completeTransactions() { [weak self] (purchases) in
            guard let self = self else { return }
            CLog.print(.info, .purchase, "Complete purchases", purchases)
            purchases.forEach {
                switch $0.transaction.transactionState {
                case .purchased, .restored:
                    if $0.needsFinishTransaction {
                        CLog.print(.debug, .purchase, "Finish Transaction ", $0.productId)
                        self.finishTransaction([$0.transaction])
                    }
                default: break
                }
            }
        }
    }
    
    public func retreiveProducts(_ completion: SuccessResult? = nil) {
        SwiftyStoreKit.retrieveProductsInfo(Set<String>(allInapps)) { [weak self] result in
            guard let self = self else { return }
            self.products = result
                .retrievedProducts
                .map { Product(product: $0) }
            if !result.invalidProductIDs.isEmpty {
                CLog.print(.error, .purchase, "invalid product_id :[\(Array(result.invalidProductIDs))]")
            }
            if let err = result.error {
                completion?(.failure(.custom(err)))
            } else {
                completion?(.success(true))
            }
        }
    }
    
    public func getPurchase(_ completion: SuccessResult? = {_ in}) {
        guard let bundleID = Bundle.main.bundleIdentifier, let deviceID = storage.deviceID?.key else {
            completion?(.failure(.badParameters))
            return
        }
        let params: [String: Any] = [
            "device_id": deviceID,
            "bundle_id": bundleID
        ]
        apiService.sendSigned(api: .getPurchases, with: params) { [weak self] (result) in
            guard let self = self else { return }
            CLog.print(.description, .purchase, "Response Purchases")
            self.handle(result: result, completion: completion)
        }
    }
    
    func verifyReceipt(_ receipt: String, completion: SuccessResult?) {
        guard let bundleID = Bundle.main.bundleIdentifier, let deviceID = storage.deviceID?.key else {
            completion?(.failure(.badParameters))
            return
        }
        let params: [String: Any] = ["bundle_id": bundleID,
                                     "receipt": receipt,
                                     "device_id" : deviceID]

        apiService.sendSigned(api: .verifyReceipt, with: params) { [weak self] (result) in
            CLog.print(.description, .purchase, "Response VerifyReceipt ")
            guard let self = self else { return }
            self.handle(result: result, completion: completion)
        }
    }
    
    func handle(result: ServerResult, completion: SuccessResult?) {
        switch result {
        case .failure(let apiError):
            CLog.print(.error, .purchase, "Response error", apiError.localizedDescription)
            completion?(.failure(apiError))
        case .success(let jsonDictionary):
            CLog.print(.description, .purchase, "Response data - ", jsonDictionary)
            if let list = jsonDictionary["purchase_list"] as? [[String: Any]] {
                purchases = list.compactMap { Purchase($0) }
                setPrices()
                storage.purchases = purchases
                completion?(.success(true))
            } else {
                completion?(.failure(.badResult))
            }
        }
    }
    
    func setPrices() {
        purchases = purchases.map { purchase in
            purchase.setPrice(for: products.first { product in product.identifier == purchase.productID } )
        }
    }
    
}

//MARK: Purchases
extension PurchaseService {
    public func makePurchase(by productId: String) {
        guard SwiftyStoreKit.canMakePayments else {
            self.purchaseResponse?(.failure(.cannotMakePayments))
            return
        }
        apiService.compareTimestamps { [weak self] error in
            guard let self = self else { return }
            if let err = error as NSError?, APIError.error(by: String(err.code)) == .invalidTimestamps {
                self.purchaseResponse?(.failure(.invalidTimestamps))
                return
            }
            SwiftyStoreKit.purchaseProduct(productId, atomically: false) { [weak self] result in
                switch result {
                case .success(purchase: let details), .deferred(purchase: let details):
                    self?.purchaseDidComplete(with: .success(details))
                    self?.fetchReceipt(transactions: [details.transaction])
                case .error(error: let error):
                    self?.purchaseDidComplete(with: .failure(error))
                }
            }
        }
    }
    
    public func restorePurchase() {
        guard SwiftyStoreKit.canMakePayments else {
            self.restoreResponse?(.failure(.cannotMakePayments))
            return
        }
        apiService.compareTimestamps { [weak self] error in
            guard let self = self else { return }
            if let err = error as NSError?, APIError.error(by: String(err.code)) == .invalidTimestamps {
                self.restoreResponse?(.failure(.invalidTimestamps))
                return
            }
            SwiftyStoreKit.restorePurchases(atomically: false) { [weak self] restoreResult in
                self?.restoreDidComplete(with: restoreResult)
                let transactions = restoreResult.restoredPurchases.compactMap { $0.transaction }
                self?.fetchReceipt(transactions: transactions)
            }
        }
    }
    
    private func fetchReceipt(transactions: [PaymentTransaction] = []) {
        SwiftyStoreKit.fetchReceipt(forceRefresh: true) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(receiptData: let receiptData):
                let encodedData = receiptData.base64EncodedString()
                self.didFetchReceipt(transactions: transactions, with: .success(encodedData))
            case .error(error: let error):
                self.didFetchReceipt(with: .failure(error))
            }
        }
    }
    
    func finishTransaction(_ transactions: [PaymentTransaction]) {
        transactions.forEach { transaction in
            CLog.print(.debug, .purchase, "Finish Transaction imediatly ", transaction)
            SwiftyStoreKit.finishTransaction(transaction)
        }
    }
}

extension PurchaseService {
    func purchaseDidComplete(with result: Result<PurchaseDetails, SKError>) {
        switch  result {
        case .failure(let error):
            CLog.print(.error, .purchase, "Purchase Complete With Error \(error.localizedDescription) ")
            if error.code == SKError.paymentCancelled {
                purchaseResponse?(.failure(.paymentCancelled))
            } else {
                purchaseResponse?(.failure(.purchase(error)))
            }
        case .success(let details):
            CLog.print(.debug, .purchase, "Purchase Complete Succes for \(details.productId) ")
            purchaseResponse?(.success(true))
        }
    }
    
    func restoreDidComplete(with result: RestoreResults) {
        let errorResults = result.restoreFailedPurchases
        if !errorResults.isEmpty {
            CLog.print(.error, .purchase, "Restore Complete With Error \(errorResults.debugDescription) for \(errorResults.compactMap { $0.1 })")
            let errors = errorResults.compactMap { $0.0 }
            if errors.first(where: { $0.code == SKError.paymentCancelled }) != nil {
                restoreResponse?(.failure(.paymentCancelled))
            } else {
                restoreResponse?(.failure(.restore(errors)))
            }
            return
        }
        CLog.print(.debug, .purchase, "Restore Complete Succes for \(result.restoredPurchases) ")
        restoreResponse?(.success(true))
    }
    
    func didFetchReceipt(transactions: [PaymentTransaction] = [], with result: Result<String, Error>) {
        switch  result {
        case .failure(let error):
            CLog.print(.error, .purchase, "didFetchReceipt Error ", error.localizedDescription)
            if purchaseResponse != nil {
                receipteResponse?(.failure(.purchaseValidateReceipt(error)))
            } else {
                receipteResponse?(.failure(.restoreValidateReceipt(error)))
            }
        case .success(let receiptData):
            verifyReceipt(receiptData) { [weak self] result in
                guard let self = self else { return }
                CLog.print(.debug, .purchase, "Puschases from receipt ")
                self.receipteResponse?(result)
                self.finishTransaction(transactions)
            }
        }
    }
}
