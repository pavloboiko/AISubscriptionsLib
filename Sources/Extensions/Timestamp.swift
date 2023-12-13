//
//  Timestamp.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/23/21.
//

import Foundation

typealias Timestamp = Double

extension Timestamp {
    
    var dateFromNowMs: Date {
        Date(timeIntervalSinceNow: TimeInterval(self/1000))
    }
    var dateFrom1970Ms: Date {
        Date(timeIntervalSince1970: TimeInterval(self/1000))
    }
    
    static func from(_ date: Date) -> Timestamp {
        date.timeIntervalSince1970*1000
    }
    
    static func now() -> Timestamp {
        Timestamp.from(Date())
    }
}
