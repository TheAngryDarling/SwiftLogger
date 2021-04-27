//
//  File.swift
//  Logger
//
//  Created by Tyler Anger on 2018-06-09.
//

import Foundation

/// A Logging class to allow logging to multiple loggers at once.
/// This way you can log to a file and the console at the same time if needed.
/// You will still need to control
public final class GroupLogger: Logger {
    
    
    private let loggers: [Logger]
    
    public init(loggers: [Logger]) {
        self.loggers = loggers
    }
    
    public convenience init(loggers: Logger...) {
        self.init(loggers: loggers)
    }
    
    public func canLog(_ level: LogLevel) -> Bool {
        return self.loggers.contains(where: { return $0.canLog(level) })
    }
    
    /// Log a message.  Do not call this method directly.  This is outlined so that concrete types that implement Logger have this method.
    /// Instead, please call the log(messaeg, level) helper method insetad.
    ///
    /// - parameters:
    ///   - message: The message to log
    ///   - level: The log level to use
    ///   - filename: The name of the file this is being called from
    ///   - line: The line number in the file that this method was called
    ///   - funcname: The name of the function that called this function
    public func logMessage(message: String,
                           level: LogLevel,
                           filename: String,
                           line: Int,
                           funcname: String,
                           additionalInfo: [String: Any]) {
        for l in self.loggers {
            l.logMessage(message: message,
                         level: level,
                         filename: filename,
                         line: line,
                         funcname: funcname,
                         additionalInfo: additionalInfo)
        }
    }
    
    /// Log a message.  Do not call this method directly.  This is outlined so that concrete types that implement Logger have this method.
    /// Instead, please call the log(messaeg, level) helper method insetad.
    ///
    /// - parameters:
    ///   - message: The message to log
    ///   - level: The log level to use
    ///   - filename: The name of the file this is being called from
    ///   - line: The line number in the file that this method was called
    ///   - funcname: The name of the function that called this function
    public func logMessage(message: String,
                           level: LogLevel,
                           source: String,
                           filename: String,
                           line: Int,
                           funcname: String,
                           additionalInfo: [String: Any]) {
        for l in self.loggers {
            l.logMessage(message: message,
                         level: level,
                         source: source,
                         filename: filename,
                         line: line,
                         funcname: funcname,
                         additionalInfo: additionalInfo)
        }
    }
}
