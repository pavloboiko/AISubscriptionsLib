//
//  PurchaseManager.swift
//  PurchaseClient
//
//  Created by iMac on 09.09.2020.
//


import Foundation
import StoreKit

public enum PeriodType {
    case day, week, month, year
    
    var string: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        }
    }
}

public enum Style {
    case minimal
    case `default`
}

public class Product: NSObject {
    
    // MARK: PROPERTIES
    public var identifier            = "Unknown"
    public var localizedTitle        = "Unknown"
    public var localizedDescription  = "Unknown"
    public var price                 = 0.0
    public var priceLocale           = Locale.current
    public var localizedPrice        = "Unknown"
    public var currencyCode          = "Unknown"
    public var period: SubscriptionPeriod?
    public var introductory: Introductory?
    
    // MARK: LIFE CYCLE
    init(identifier id: String) {
        identifier = id
    }
    
    convenience init(product: SKProduct) {
        self.init(identifier: product.productIdentifier)
        
        localizedTitle        = product.localizedTitle
        localizedDescription  = product.localizedDescription
        price                 = product.price.doubleValue.round(to: 2)
        priceLocale           = product.priceLocale
        localizedPrice        = product.localizedPrice ?? "Unknown"
        currencyCode          = product.priceLocale.currencySymbol ?? "Unknown"
        period                = SubscriptionPeriod(period: product.subscriptionPeriod)
        introductory          = Introductory(discount: product.introductoryPrice)
    }
    
    public func localizedPrice(_ price: Double) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: NSNumber(value: price))
    }
}


public class SubscriptionPeriod: NSObject {
    public var numberOfUnits = 0
    var formattedString = ""
    var perFormattedString = ""
    public var unit = PeriodType.day
    
    init(period: SKProductSubscriptionPeriod?) {
        guard let period = period else { return }
        numberOfUnits = period.numberOfUnits
        
        switch period.unit {
        case .day:
            unit = .day
            formattedString = "\(period.numberOfUnits) day"
            perFormattedString = "\(period.numberOfUnits) day"
            if period.numberOfUnits > 1 { formattedString += "s" }
            if period.numberOfUnits == 7 {
                formattedString = "Weekly"
                perFormattedString = "week"
                unit = .week
            }
        case .week:
            unit = .week
            formattedString = "\(period.numberOfUnits) week"
            perFormattedString = "\(period.numberOfUnits) week"
            if period.numberOfUnits == 1 {
                formattedString = "Weekly"
                perFormattedString = "week"
            }
            if period.numberOfUnits > 1 { formattedString += "s"; perFormattedString += "s" }
        case .month:
            unit = .month
            formattedString = "\(period.numberOfUnits) month"
            perFormattedString = "\(period.numberOfUnits) month"
            if period.numberOfUnits == 1 {
                formattedString = "Monthly"
                perFormattedString = "month"
            }
            if period.numberOfUnits > 1 { formattedString += "s"; perFormattedString += "s" }
        case .year:
            unit = .year
            formattedString = "\(period.numberOfUnits) year"
            perFormattedString = "year"
            if period.numberOfUnits == 1 { formattedString = "Yearly"}
            if period.numberOfUnits > 1 { formattedString += "s" }
        default: break
        }
    }
}

public class Introductory: NSObject {
    public var price = 0.0
    public var localizedPrice = ""
    public var period: DiscountSubscriptionPeriod?
    public var isTrial = true
    
    init(discount: SKProductDiscount?) {
        super.init()
        guard let discount = discount else { return }
        
        price = discount.price.doubleValue
        isTrial = price == 0 ? true : false
        localizedPrice = localizedPrice(price) ?? "0.0"
        period = DiscountSubscriptionPeriod(period: discount.subscriptionPeriod,
                                            numberOfPeriods: discount.numberOfPeriods,
                                            isTrial: isTrial)
    }
    
    private func localizedPrice(_ price: Double, localeIdentifier: String? = "en_US") -> String? {
        guard let uIdentifier = localeIdentifier else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: uIdentifier)
        return formatter.string(from: NSNumber(value: price))
    }
}


public class DiscountSubscriptionPeriod: NSObject {
    public var numberOfUnits = 0
    var formattedString = ""
    public var unit = PeriodType.day
    var promoPeriod = ""
    
    init(period: SKProductSubscriptionPeriod?, numberOfPeriods: Int, isTrial: Bool) {
        guard let period = period else { return }
        numberOfUnits = numberOfPeriods == 1 ? period.numberOfUnits : numberOfPeriods
        
        switch period.unit {
        case .day:
            unit = .day
            formattedString = "\(numberOfUnits) day"
            if numberOfUnits == 7, !isTrial { formattedString = "week"; unit = .week }
            if numberOfUnits > 1 { formattedString += "s" }
            
            promoPeriod = "\(numberOfUnits) day"
            if numberOfUnits > 1 { promoPeriod += "s" }
            if numberOfUnits == 7 { promoPeriod = "1 week" }
        case .week:
            unit = .week
            formattedString = "\(numberOfUnits) week"
            if numberOfUnits == 1, !isTrial { formattedString = "week"}
            if numberOfUnits > 1 { formattedString += "s" }
            
            promoPeriod = "\(numberOfUnits) week"
            if numberOfUnits > 1 { promoPeriod += "s" }
        case .month:
            unit = .month
            formattedString = "\(numberOfUnits) month"
            if numberOfUnits == 1, !isTrial { formattedString = "month"}
            if numberOfUnits > 1 { formattedString += "s" }
            
            promoPeriod = "\(numberOfUnits) month"
            if numberOfUnits > 1 { promoPeriod += "s" }
        case .year:
            unit = .year
            formattedString = "\(numberOfUnits) year"
            if numberOfUnits == 1, !isTrial { formattedString = "year"}
            if numberOfUnits > 1 { formattedString += "s" }
            
            promoPeriod = "\(numberOfUnits) year"
            if numberOfUnits > 1 { promoPeriod += "s" }
        default: break
        }
    }
}
