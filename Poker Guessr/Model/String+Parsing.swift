//
//  String+Parsing.swift
//  Poker Guessr
//

import Foundation

extension String {
    func extractFirstDouble() -> Double? {
        let pattern = "[-+]?[0-9]+([.,][0-9]+)?"
        if let range = self.range(of: pattern, options: .regularExpression) {
            let numStr = self[range].replacingOccurrences(of: ",", with: ".")
            return Double(numStr)
        }
        return nil
    }
}
