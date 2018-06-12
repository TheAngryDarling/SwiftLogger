//
//  LoggerBase.swift
//  Logger
//
//  Created by Tyler Anger on 2018-06-09.
//

import Foundation

public class LoggerBase: Logger {
    
    public struct LogInfo {
        let date: Date
        let level: LogLevel
        let message: String
        let processIdentifier: Int32
        let processName: String
        let threadName: String?
        let filename: String
        let line: Int
        let funcname: String
        let stackSymbols: [String]
        let additionalInfo: [String: Any]
        
        public init(date: Date = Date(),
                    level: LogLevel,
                    message: String,
                    processIdentifier: Int32 = ProcessInfo.processInfo.processIdentifier,
                    processName: String = ProcessInfo.processInfo.processName,
                    thread: Thread = Thread.current,
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
            if let n = thread.name, !n.isEmpty { self.threadName = n }
            else if thread.isMainThread { self.threadName = "main" }
            else { self.threadName = nil }
            self.filename = filename
            self.line = line
            self.funcname = funcname
            self.stackSymbols = stackSymbols
            self.additionalInfo = additionalInfo
        }
        
        
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
    
    public static let STANDARD_DATE_FORMAT: String = "yyyy-MM-dd'T'HH:mm:ss:SSSZ"
    
    internal var loggerQueue: Queue
   
    
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
