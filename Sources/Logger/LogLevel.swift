//
//  LogLevel.swift
//  Logger
//
//  Created by Tyler Anger on 2018-06-09.
//

import Foundation

/// A structure to define a log level
public struct LogLevel {
    
    private static let MIN_LOG_LEVEL: Double = 0.0
    private static let MAX_LOG_LEVEL: Double = 600.0
    public static let any = LogLevel(MIN_LOG_LEVEL, name: "any")
    public static let debug = LogLevel(100, name: "debug", symbol: "✳️")
    public static let info = LogLevel(200, name: "info", symbol: "ℹ️")
    public static let warn = LogLevel(300, name: "warn", symbol: "⚠️")
    public static let error = LogLevel(400, name: "error", symbol: "🚫")
    public static let fatal = LogLevel(500, name: "fatal", symbol: "🆘")
    public static let none = LogLevel(MAX_LOG_LEVEL, name: "none")
    
    /// The score (or weight) of the log level.  Used when determing of the log message should be written
    private let score: Double
    /// The Log name (light debug, info, warn, error, fatal)
    public let name: String
    /// The SDT Output name (ususal this is the name in uppercase)
    public let STDName: String
    /// Optional symbol for the log level (like a stop or warning sign)
    public let symbol: String?
    
    /// Create a new log level
    ///
    /// - Parameters:
    ///   - score: The score of the level.  This is used to determing if the log message should be wirtten
    ///   - name: The Name of the log level
    ///   - STDName: The STD Name of the log level
    ///   - symbol: The Symbol of the log level
    public init(_ score: Double, name: String, STDName: String, symbol: String?) {
        precondition(score >= LogLevel.MIN_LOG_LEVEL && score <= LogLevel.MAX_LOG_LEVEL, "Log level score must be greater than or equal to \(LogLevel.any.score) and less than or equal to \(LogLevel.none.score)")
        self.score = score
        self.name = name
        self.STDName = STDName
        self.symbol = symbol
    }
    
    /// Create a new log level
    ///
    /// - Parameters:
    ///   - score: The score of the level.  This is used to determing if the log message should be wirtten
    ///   - name: The Name of the log level
    ///   - STDName: The STD Name of the log level
    public init(_ score: Double, name: String, STDName: String) {
        self.init(score, name: name, STDName: STDName, symbol: nil)
    }
    
    /// Create a new log level
    ///
    /// - Parameters:
    ///   - score: The score of the level.  This is used to determing if the log message should be wirtten
    ///   - name: The Name of the log level
    public init(_ score: Double, name: String) {
        self.init(score, name: name, STDName: name.uppercased())
    }
    
    /// Create a new log level
    ///
    /// - Parameters:
    ///   - score: The score of the level.  This is used to determing if the log message should be wirtten
    ///   - name: The Name of the log level
    ///   - symbol: The Symbol of the log level
    public init(_ score: Double, name: String, symbol: String) {
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
