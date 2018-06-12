//
//  ConsoleLogger.swift
//  Logger
//
//  Created by Tyler Anger on 2018-06-09.
//

import Foundation

/**
 Used to log to the console.
 */
public class ConsoleLogger: LoggerBase {
    public var logLevel: LogLevel
    public var logFormat: ((LogInfo)->String)
    private let dateFormatter: DateFormatter
    
    /**
     Create new instance of Cosole
     - parameters:
     - logQueueName: The name of the queue used for logging (Default is nil)
     - withLogLevel: The starting level for this logger (Default is .error)
     - usingDateFormat: Date format for date used in log file (Default is 'yyyy-MM-dd'T'HH:mm:ss:SSSZ')
     - withLogFormat: Keyed format in which to log with.  Keys are: log_level, date, process_name, thread, file_name, file_line, function_name, message.  Log_level has the following sub properties: name, STDName, symbol.  To create your own keyedFormat please refer to IndexedStringFormat
     */
    public init(logQueueName: String? = nil,
                withlogLevel logLevel: LogLevel = .error,
                usingDateFormat dateFormat: String = LoggerBase.STANDARD_DATE_FORMAT,
                withLogFormat logformat: @escaping (LogInfo)->String = ConsoleLogger.defaultLogFormat) {
        self.logLevel = logLevel
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = dateFormat
        self.logFormat = logformat
        super.init(logQueueName: logQueueName, useAsyncLogging: false)
    }
    
    public static func defaultLogFormat(_ info: LogInfo) -> String {
        return "%{log_level:@.symbol} - %{date} - %{process_name} - %{thread} - %{file_name}:%{file_line} - %{function_name} - %{log_level:@.STDName} - %{message}"
    }
    
    internal override func canLogLevel(forInfo info: LogInfo) -> Bool {
        return (info.level >= self.logLevel)
    }
    
    internal override func logLine(_ info: LoggerBase.LogInfo) {
        
        let keyedData = info.dictionary(usingDateFormat: dateFormatter)
        
        let line = String(withKeyedFormat: self.logFormat(info), keyedData)
        print(line)
        
        /*let levelInfoSec: String = {
            var rtn: String = self.useSTDNaming ?  info.level.STDName : info.level.name
            if self.showEmojis { rtn = "(\(info.level.symbol))" + rtn }
            return rtn
        }()
        let threadName: String = info.threadName ?? "nil"
        
        
        let line = "[\(levelInfoSec)] [\(dateFormatter.string(from: info.date))] [\(info.processName):\(info.processIdentifier)] [\(threadName)] [\(info.filename):(\(info.line))] [\(info.funcname)]: \(info.message)"*/
        
        
        //Using fputs instead of print because sometines when using print the message gets broken up when another thread prints at the same time
        //fputs(line + "\n", stdout)
        fflush(stdout)
    }
}

/*
 A Console logger which only logs messages when the log level provided matches the one in the logger
 */
public class ExplicitConsoleLogger: ConsoleLogger {
    internal override func canLogLevel(forInfo info: LogInfo) -> Bool {
        return (info.level == self.logLevel)
    }
}

//Global access to concole logger
public let consoleLogger: ConsoleLogger = ConsoleLogger()
