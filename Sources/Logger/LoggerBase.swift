//
//  LoggerBase.swift
//  Logger
//
//  Created by Tyler Anger on 2018-06-09.
//

import Foundation
#if os(Linux)
import Dispatch
import Glibc
#endif

/// A Base helper class for Loggers
public class LoggerBase: Logger {
    
    /// A structure containing all the details about a log message
    public struct LogInfo {
        public let date: Date
        public let level: LogLevel
        public let message: String
        public let processIdentifier: Int32
        public let processName: String
        public let threadName: String?
        public let filename: String
        public let line: Int
        public let funcname: String
        public let additionalInfo: [String: Any]
        private let stackSymbols: [String]
        
        public init(date: Date = Date(),
                    level: LogLevel,
                    message: String,
                    processIdentifier: Int32 = ProcessInfo.processInfo.processIdentifier,
                    processName: String = ProcessInfo.processInfo.processName,
                    threadName: String? = {
                        if let n = Thread.current.name, !n.isEmpty { return n }
                        else if Thread.current.isMainThread { return "main" }
                        return nil
                    }(),
                    filename: String,
                    line: Int,
                    funcname: String,
                    stackSymbols: [String] = Thread.callStackSymbols,
                    additionalInfo: [String: Any] = [:]) {
            self.date = date
            self.level = level
            self.message = message
            self.processIdentifier = processIdentifier
            self.processName = processName
            self.threadName = threadName
            self.filename = filename
            self.line = line
            self.funcname = funcname
            self.stackSymbols = stackSymbols
            self.additionalInfo = additionalInfo
        }
        
        
        /// Converts a LogInfo message to a dictionary of data
        ///
        /// - Parameter dateFormatter: The date format to use when converting dates to strings
        /// - Returns: Returns a dictionary of all the message details
        public func dictionary(usingDateFormat dateFormatter: DateFormatter) -> [String: Any?] {
            var rtn: [String: Any?] =  [
                "date": dateFormatter.string(from: self.date),
                "date_object": self.date,
                "thread": self.threadName,
                "process_name": self.processName,
                "log_level": self.level,
                "file_name": self.filename,
                "file_line": self.line,
                "function_name": self.funcname,
                "message": self.message,
                "additional_info": self.additionalInfo
            ]
            //Directly add the additional info keys as well.
            for (k,v) in self.additionalInfo {
                rtn[k] = v
            }
            
            
            return rtn
        }
        
    }
    
    internal enum Queue {
        case dispatch(DispatchQueue)
        case operation(OperationQueue)
        
        public init(dispatchName: String) {
            self = .dispatch(DispatchQueue(label: dispatchName))
        }
        public init(operationName: String? = nil, withMaxConcurrentOperations: Int) {
            let oq = OperationQueue()
            oq.maxConcurrentOperationCount = withMaxConcurrentOperations
            if let n = operationName { oq.name = n }
            
            self = .operation(oq)
        }
        
        public var operationCount: Int {
            guard case let .operation(op) = self else { return 0 }
            return op.operationCount
        }
        
        public func add(_ block: @escaping () -> Swift.Void) {
            switch self {
                case .dispatch(let dq): dq.sync(execute: block)
                case .operation(let oq): oq.addOperation(block)
            }
        }
        
    }
    
    /// The standard date format to use when converting dates to strings
    public static let STANDARD_DATE_FORMAT: String = "yyyy-MM-dd'T'HH:mm:ss:SSSZ"
    
    internal var loggerQueue: Queue
   
    
    /// Creates a new instance of the Logger base
    ///
    /// - Parameters:
    ///   - logQueueName: optional name for the DispatchQueue used when logging messages
    ///   - useAsyncLogging: Indicator if logging should be done asynchronously (Default: True)
    public init(logQueueName: String?, useAsyncLogging: Bool = true) {
        if useAsyncLogging { self.loggerQueue = Queue(operationName: logQueueName, withMaxConcurrentOperations: 1) }
        else {
            let lName = logQueueName ?? "logger.LoggerBase.dispatch"
            self.loggerQueue = Queue(dispatchName: lName)
        }
        
        precondition(type(of: self) != LoggerBase.self, "Can not initiate abstract class LoggerBase.  Please use class that inherits it.")
    }
    
    deinit {
        //We should  wait until all logs are finished
        while self.loggerQueue.operationCount > 0 {
            Thread.sleep(forTimeInterval: 0.05)
        }
        //Wait just a little longer for good measure. (Trying to allow for any flushing
        Thread.sleep(forTimeInterval: 0.5)
        
    }
    
    
    internal func canLogLevel(forInfo info: LogInfo) -> Bool {
        precondition(type(of: self) != LoggerBase.self, "Can not call abstract method LoggerBase.canLogLevel.  Please use class that inherits it.")
        return false
    }
    
    
    public func logMessage(message: String,
                           level: LogLevel,
                           filename: String,
                           line: Int,
                           funcname: String,
                           additionalInfo: [String: Any]) {
        
        let info = LogInfo(level: level,
                           message: message,
                           filename: filename,
                           line: line,
                           funcname: funcname,
                           additionalInfo: additionalInfo)
        
        if self.canLogLevel(forInfo: info) {
            self.loggerQueue.add {
                self.logLine(info)
            }
        }
    }
    
    internal func logLine(_ info: LogInfo) {
        precondition(type(of: self) != LoggerBase.self, "Can not call abstract method LoggerBase.log.  Please use class that inherits it.")
    }
    
}
