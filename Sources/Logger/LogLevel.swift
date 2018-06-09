//
//  LogLevel.swift
//  Logger
//
//  Created by Tyler Anger on 2018-06-09.
//

import Foundation

public struct LogLevel {
    
    public static let debug = LogLevel(1, name: "debug", symbol: "✳️")
    public static let info = LogLevel(2, name: "info", symbol: "ℹ️")
    public static let warn = LogLevel(3, name: "warn", symbol: "⚠️")
    public static let error = LogLevel(4, name: "error", symbol: "🚫")
    public static let fatal = LogLevel(5, name: "fatal", symbol: "🆘")
    public static let none = LogLevel(6, name: "none")
    
    private let score: Int
    public let name: String
    public let STDName: String
    public let symbol: String?
    
    private init(_ score: Int, name: String, STDName: String, symbol: String?) {
        self.score = score
        self.name = name
        self.STDName = STDName
        self.symbol = symbol
    }
    
    private init(_ score: Int, name: String, STDName: String) {
        self.init(score, name: name, STDName: STDName, symbol: nil)
    }
    
    private init(_ score: Int, name: String) {
        self.init(score, name: name, STDName: name.uppercased())
    }
    
    private init(_ score: Int, name: String, symbol: String) {
        self.init(score, name: name, STDName: name.uppercased(), symbol: symbol)
    }
}

extension LogLevel: Comparable {
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.score < rhs.score
    }
    
    public static func == (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.score == rhs.score
    }
    
}
extension LogLevel: CustomStringConvertible {
    public var description: String { return self.STDName }
}
