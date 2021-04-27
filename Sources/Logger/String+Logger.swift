//
//  String+Logger.swift
//  Logger
//
//  Created by Tyler Anger on 2021-04-26.
//

import Foundation
#if !swift(>=4.1.4)
internal extension String {
    func firstIndex(of character: Character) -> String.Index? {
        return self.range(of: "\(character)")?.lowerBound
    }
}
#endif
