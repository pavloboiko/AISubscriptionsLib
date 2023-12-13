//
//  ResultsType.swift
//
//  Created by Serjant Alexandru on 3/1/21.
//

import Foundation

public typealias AISubsResult = Result<Bool, APIError>
public typealias SuccessResult = (AISubsResult)->Void
public typealias ErrorResult = (APIError)->Void
