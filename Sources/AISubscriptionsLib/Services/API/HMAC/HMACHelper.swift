//
//  HMACHelper.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 1/20/21.
//

import Foundation

final class HMACHelper {
    
    static let shared = HMACHelper()
    
    static func jsonString(from params: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: params, options: .fragmentsAllowed) else { return nil }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return nil }
        return jsonString
    }
    
    static func hash(from params: [String: Any]) -> String? {
        guard let jsonString = jsonString(from: params) else { return nil }
        let newHash = jsonString.hmac(algorithm: .SHA256, key: Secret.key(with: "$"))
        return newHash
    }
    
    static func decode(jwtToken jwt: String) throws -> [String: Any] {
        
        enum DecodeErrors: Error {
            case badToken
            case other
        }
        
        func base64Decode(_ base64: String) throws -> Data {
            let padded = base64.padding(toLength: ((base64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
            guard let decoded = Data(base64Encoded: padded) else {
                throw DecodeErrors.badToken
            }
            return decoded
        }
        
        func decodeJWTPart(_ value: String) throws -> [String: Any] {
            let bodyData = try base64Decode(value)
            let json = try JSONSerialization.jsonObject(with: bodyData, options: [])
            guard let payload = json as? [String: Any] else {
                throw DecodeErrors.other
            }
            return payload
        }
        
        let segments = jwt.components(separatedBy: ".")
        if segments.count>1 {
            return try decodeJWTPart(segments[1])
        }
        return [:]
    }
}
