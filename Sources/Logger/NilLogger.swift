//
//  File.swift
//  Logger
//
//  Created by Tyler Anger on 2018-06-09.
//

import Foundation


fileprivate class NilLogger: Logger {
    func logMessage(message: String, level: LogLevel, filename: String, line: Int, funcname: String, additionalInfo: [String: Any]) {
        //Do Nothing here
    }
}

// Global access to nil logger
public let nilLogger: Logger = NilLogger()
