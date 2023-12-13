//
//  APIError.swift
//  PurchaseClientDemo
//
//  Created by Serjant Alexandru on 3/16/21.
//

import Foundation
import StoreKit

public enum APIError: Error {
    case none
    case other
    case signature
    case invalidTimestamps
    case deviceNotFound
    case invalidEmail
    case cantConsumeAttempts
    case cantConsumeBonus
    
    case response
    case badParameters
    case noConnection
    case custom(Error)
    case badResult
    case expired
    
    case badResponse500

    case purchase(SKError)
    case paymentCancelled
    case restore([SKError])
    case purchaseValidateReceipt(Error)
    case restoreValidateReceipt(Error)
    case cannotMakePayments
    
    case emptyConsumableAttempts
    case consumeConsumable
    
    case eulaNotFound
    case policyNotFound
    
    var name: String {
        get { return String(describing: self) }
    }
    
    static func error(by code: String?) -> APIError {
        guard let code = code, let codeError = Int(code) else { return .other }
        switch codeError {
        case 0:
            return .none
        case 1:
            return .invalidTimestamps
        case 30:
            return .signature
        case 31:
            return .signature
        case 32:
            return .invalidEmail
        case 73:
            return .cantConsumeAttempts
        case 74:
            return .cantConsumeBonus
        case 131:
            return .eulaNotFound
        case 132:
            return .policyNotFound
        case 158:
            return .emptyConsumableAttempts
        case 159:
            return .consumeConsumable
        case 500:
            return .badResponse500
        case 1100:
            return .badResult
        default:
            break
        }
        return .other
    }
}

extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        lhs.name == rhs.name
    }
}
