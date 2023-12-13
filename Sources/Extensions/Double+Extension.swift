//
//  Double+Extension.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/18/21.
//

import Foundation

extension Double {

    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
}
