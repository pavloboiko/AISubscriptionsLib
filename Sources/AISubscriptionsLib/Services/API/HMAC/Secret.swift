//
//  Secret.swift
//  PurchaseClientDemo
//
//  Created by Serjant Alexandru on 3/2/21.
//

import Foundation

struct Secret {
    
    private static let secKey: [[String: [UInt8]]] =
        [["00Td5aGs": [0xB9, 0xCF, 0xB8, 0xC3, 0xFF, 0xFF, 0xF8, 0xEC]],
         ["00BXlbSr": [0xE4, 0xBE, 0xE4, 0xDA, 0xCF, 0xE8, 0xBB, 0xC6]],
         ["02pHjgkI": [0xDE, 0xE7, 0xC0, 0xD7, 0xBB, 0xDC, 0xBD, 0xEB]],
         ["ZNlTfl52": [0xE4, 0xC6, 0xD8, 0xE4, 0xC5, 0xEA, 0xD7, 0xC4]],
         ["0NuSS9HF": [0xE9, 0xC3, 0xBA, 0xE4, 0xD4, 0xDE, 0xB9, 0xCF]],
         ["aXoDggpZ": [0xDD, 0xEA, 0xE3, 0xFA, 0xDE, 0xFF, 0xE6, 0xC0]],
         ["00auhZqY": [0xCF, 0xD6, 0xBB, 0xB8, 0xC0, 0xD8, 0xE2, 0xCD]],
         ["00hLK10J": [0xE0, 0xC7, 0xE4, 0xD4, 0xDB, 0xBD, 0xEB, 0xBF]]]
    
    static func key(with salt: Character) -> String {
        return decode(array: secKey, salt: salt)
    }
    
    private static func decode(array: [[String: [UInt8]]], salt: Character) -> String {
        let emptyCh = "'"
        let bitMask = 0b10101010
        guard let additiontSalt = salt.asciiValue else { return "non valid character" }
        let arrangeArray = array.sorted { (lhs, rhs) -> Bool in
            if let lKey = lhs.keys.first, let rKey = rhs.keys.first {
                return lKey > rKey
            }
            return false
        }
        let newArray = arrangeArray.compactMap { $0.first?.value }
            .map { $0
                .map(Int.init)
                .map { $0 ^ bitMask ^ Int(additiontSalt) }
                .compactMap(UnicodeScalar.init)
            }
        
        var text = newArray.map { $0.compactMap(String.init).reversed().joined() }.joined()
        while text.hasSuffix(emptyCh) { text.removeLast(1) }
        return text
    }
}
