//
//  Bundle+Extensions.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/4/21.
//

import Foundation

extension Bundle {
    
  var releaseVersionNumber: String? {
    return infoDictionary?["CFBundleShortVersionString"] as? String
  }
    
  var buildVersionNumber: String? {
    return infoDictionary?["CFBundleVersion"] as? String
  }
    
}
