//
//  Strings+Extensions.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 1/28/21.
//

import Foundation

extension String {
    
    public var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
}
