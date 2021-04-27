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
        public let source: String
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
                    threadName: String? = nil,
                    source: String = "N/A",
                    filename: String,
                    line: Int,
                    funcname: String,
                    stackSymbols: [String]? = nil,
                    additionalInfo: [String: Any] = [:]) {
            self.date = date
            self.level = level
            self.message = message
            self.processIdentifier = processIdentifier
            self.processName = processName
            self.threadName = threadName ?? {
                if let n = Thread.current.name, !n.isEmpty { return n }
                else if Thread.current._isMainThread { return "main" }
                return nil
                }()
            self.source = source
            self.filename = filename
            self.line = line
            self.funcname = funcname
            self.stackSymbols = stackSymbols ?? Thread._callStackSymbols
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
                "source": self.source,
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
    
    /// Queue used when logging
    internal enum Queue {
        case sync(DispatchQueue)
        case async(OperationQueue)
        
        /// Create new queue
        /// - Parameter syncName: Naame to call queue
        public init(syncName: String) {
            self = .sync(DispatchQueue(label: syncName))
        }
        /// Crate new queue
        /// - Parameters:
        ///   - asyncName: Naame to call queue
        ///   - withMaxConcurrentOperations: Maximum opersions to execure on queue at any given time
        public init(asyncName: String, withMaxConcurrentOperations: Int) {
            let dq = DispatchQueue(label: asyncName)
            let oq = OperationQueue()
            oq.underlyingQueue = dq
            oq.maxConcurrentOperationCount = withMaxConcurrentOperations
            oq.name = asyncName
            
            self = .async(oq)
        }
        
        /// Returns the current number of operations on the queue
        /// For sync queues this will always return 0
        public var operationCount: Int {
            guard case let .async(op) = self else { return 0 }
            return op.operationCount
        }
        
        /// Addes a block to the given queue
        ///
        /// If the queue is a synchronous, it will call DispatchQueue.sync and wait for block to finish before returning
        /// - Parameter block: Block to execute on the queue
        public func add(_ block: @escaping () -> Swift.Void) {
            switch self {
                case .sync(let dq): dq.sync(execute: block)
                case .async(let oq): oq.addOperation(block)
            }
        }
        
    }
    
    /// The standard date format to use when converting dates to strings
    public static let STANDARD_DATE_FORMAT: String = "yyyy-MM-dd'T'HH:mm:ss:SSSZ"
    
    /// The queue for the current logger
    internal var loggerQueue: Queue
   
    
    /// Creates a new instance of the Logger base
    ///
    /// Note: This is an abstract class.  Must be inherited for use
    /// - Parameters:
    ///   - logQueueName: optional name for the DispatchQueue used when logging messages
    ///   - useAsyncLogging: Indicator if logging should be done asynchronously (Default: True)
    public init(logQueueName: String?, useAsyncLogging: Bool = true) {
         let lName = logQueueName ?? "logger.LoggerBase.dispatch"
        if useAsyncLogging {
            self.loggerQueue = Queue(asyncName: lName,
                                     withMaxConcurrentOperations: 1)
        } else {
            self.loggerQueue = Queue(syncName: lName)
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
    
    
    public func canLog(_ level: LogLevel) -> Bool {
        precondition(type(of: self) != LoggerBase.self, "Can not call abstract method LoggerBase.canLog.  Please use class that inherits it.")
        return false
    }
    
    public func logMessage(message: String,
                           level: LogLevel,
                           source: String,
                           filename: String,
                           line: Int,
                           funcname: String,
                           additionalInfo: [String: Any]) {
        
        let info = LogInfo(level: level,
                           message: message,
                           source: source,
                           filename: filename,
                           line: line,
                           funcname: funcname,
                           additionalInfo: additionalInfo)
        
        if self.canLog(info.level) {
            self.loggerQueue.add {
                self.logLine(info)
            }
        }
    }
    
    public func logMessage(message: String,
                           level: LogLevel,
                           filename: String,
                           line: Int,
                           funcname: String,
                           additionalInfo: [String : Any]) {
        let source = Thread.current.currentLoggerSource ?? "N/A"
        let info = LogInfo(level: level,
                           message: message,
                           source: source,
                           filename: filename,
                           line: line,
                           funcname: funcname,
                           additionalInfo: additionalInfo)
        
        if self.canLog(info.level) {
            self.loggerQueue.add {
                self.logLine(info)
            }
        }
    }
    /// Log the given info
    /// - Parameter info: The info wanting to be logged
    internal func logLine(_ info: LogInfo) {
        precondition(type(of: self) != LoggerBase.self, "Can not call abstract method LoggerBase.logLine.  Please use class that inherits it.")
    }
    
}
