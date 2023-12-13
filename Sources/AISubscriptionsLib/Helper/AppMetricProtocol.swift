//
//  AppMetricProtocol.swift
//  PurchaseClientDemo
//
//  Created by Alexandru on 22.02.2022.
//

import Foundation

public protocol AppMetricProtocol {
    
    func start(request: URLRequest)
    func cancel(request: URLRequest, response: URLResponse?)
    
}

