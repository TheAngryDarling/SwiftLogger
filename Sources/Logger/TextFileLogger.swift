//
//  TextFileLogger.swift
//  Logger
//
//  Created by Tyler Anger on 2018-06-09.
//

import Foundation
import IndexedStringFormat

/// Class for logging to a text file
public class TextFileLogger: FileLogger {
    
    public static let LOG_FORMAT_DEFAULT: String = "%{date} - %{process_name} - %{thread} - %{file_name}:%{file_line} - %{function_name} - %{log_level:@.STDName} - %{message}"
    public static let LOG_FORMAT_WITH_SOURCE: String = "%{date} - %{process_name} - %{source} - %{thread} - %{file_name}:%{file_line} - %{function_name} - %{log_level:@.STDName} - %{message}"
    
    private let encoding: String.Encoding
    private let dateFormatter: DateFormatter
    private let logformat: String
    
    
    
    /// Create new instance of FileLogger
    ///
    /// - parameters:
    ///   - file: The file to write the logs to
    ///   - rollover: Indicates if and when to roll over files (Default is .none)
    ///   - encoding: The encoding to use when reading & writting to file (Default is utf8)
    ///   - logQueueName: The name of the queue used for logging (Default is nil)
    ///   - logLevel: The starting level for this logger (Default is .error)
    ///   - useAsyncLogging: Indicates of logging should be done asynchronously (Default is false)
    ///   - dateFormat: Date format for date used in log file (Default is 'yyyy-MM-dd'T'HH:mm:ss:SSSZ')
    ///   - logformat: Keyed format in which to log with.  Keys are: log_level, date, process_name, thread, file_name, file_line, function_name, message.  Log_level has the following sub properties: name, STDName, symbol.  To create your own keyedFormat please refer to IndexedStringFormat
    public init(usingFile file: String,
                rollover: FileRollover = .none,
                withStringEncoding encoding: String.Encoding = .utf8,
                logQueueName: String? = nil,
                withlogLevel logLevel: LogLevel = .error,
                useAsyncLogging: Bool = false,
                usingDateFormat dateFormat: String = LoggerBase.STANDARD_DATE_FORMAT,
                withLogFormat logformat: String = TextFileLogger.LOG_FORMAT_DEFAULT) {
        
        self.encoding = encoding
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = dateFormat
        self.logformat = logformat
       
        super.init(usingFile: file, rollover: rollover, logQueueName: logQueueName, withlogLevel: logLevel , useAsyncLogging: useAsyncLogging)
    }
    
    internal override func logInfo(_ info: LoggerBase.LogInfo) {
        
        let keyedData = info.dictionary(usingDateFormat: dateFormatter)
        
        
        let line = String(withKeyedFormat: self.logformat, keyedData) + "\n"
        //let threadName: String = info.threadName ?? "nil"
        //var line: String = "\(dateFormatter.string(from: info.date)) - \(info.processName):\(info.processIdentifier) (\(threadName)) - \(info.level.STDName) - \(info.filename):\(info.line) - \(info.funcname) - \(info.message)"
        
        //Get Data
        guard let data = line.data(using: self.encoding, allowLossyConversion: false) else {
            
            self.triggerError(Error.unableToCovertStringToData(line))
            return
        }
        
        let fileURL = URL(fileURLWithPath: self.file)
        var hasSpaceForWriting: Bool = true
        //if #available(macOS 10.13, *) {
        if let values = try? FileManager.default.attributesOfItem(atPath: self.file) {
            if let capacity = values[FileAttributeKey.systemSize] as? UInt64 {
                if capacity < data.count {
                    hasSpaceForWriting = false
                }
            }
        }
        //}
        
        guard hasSpaceForWriting else {
            self.triggerError(Error.noAvailableStorage)
            return
        }
        
        if FileManager.default.fileExists(atPath: self.file) {
            if let fileHandle = FileHandle(forWritingAtPath: self.file) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
            else {
                self.triggerError(Error.unableToOpenFile(self.file))
            }
        } else {
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                self.triggerError(Error.unableToCreateFile(self.file))
            }
        }
        
       
        
    }
    
}

/// A File logger which only logs messages when the log level provided matches the one in the logger
public class ExplicitTextFileLogger: TextFileLogger {
    /*internal override func canLogLevel(forInfo info: LogInfo) -> Bool {
        return (info.level == self.logLevel)
    }*/
    
    public override func canLog(_ level: LogLevel) -> Bool {
        return (level == self.logLevel)
    }
}
