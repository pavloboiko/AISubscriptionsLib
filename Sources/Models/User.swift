//
//  File.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 1/27/21.
//

import Foundation

public enum RegistrationSource: String, Codable {
    case none, siwa, sev
    
    static let `default`: RegistrationSource = .none
}

public struct User: Codable {
    var deviceID: String
    var userID: String?
    var authCode: String?
    var idenToken: String?
    public var givenName: String?
    public var familyName: String?
    public var name: String?
    public var email: String?
    public var source: RegistrationSource = .default
    public var isVerified: Bool = false
    public var confirmationCodeIsValid: Bool = true

}
