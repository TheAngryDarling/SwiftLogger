//
//  JSONFileLogger.swift
//  IndexedStringFormat
//
//  Created by Tyler Anger on 2018-06-09.
//

import Foundation

public class JSONFileLogger: FileLogger {
    
    public static let DEFAULT_LOGGING_KEYS: [String] = ["date","thread","process_name","log_level","file_name","file_line","function_name","message"]
    public static let DEFAULT_KEY_MAPPING: [String: String] = ["process_name": "process",
                                                               "log_level": "level",
                                                               "log_level_name": "level_name",
                                                               "log_level_STDname": "level_STDname",
                                                               "log_level_symbol": "level_symbol",
                                                               "file_name" : "file",
                                                               "file_line": "line",
                                                               "function_name": "function"]
    
    private let encoding: String.Encoding
    private let dateFormatter: DateFormatter
    private let loggingKeys: [String]
    private let keyMapping: [String: String]
    
    
    /// Create new instance of FileLogger
    /// - parameters:
    ///   - usingFile: The file to write the logs to
    ///   - rollover: Indicates if and when to roll over files (Default is .none)
    ///   - encoding: The encoding to use when reading & writting to file (Default is utf8)
    ///   - logQueueName: The name of the queue used for logging (Default is nil)
    ///   - logLevel: The starting level for this logger (Default is .error)
    ///   - useAsyncLogging: Indicates of logging should be done asynchronously (Default is false)
    ///   - dateFormat: Date format for date used in log file (Default is 'yyyy-MM-dd HH:mm:ss:SSS')
    ///   - loggingKeys: Object Keys to log
    ///   - keyMapping: Mapping of log parameter names to names to write json log
    public init(usingFile file: String,
                rollover: FileRollover = .none,
                withStringEncoding encoding: String.Encoding = .utf8,
                logQueueName: String? = nil,
                withlogLevel logLevel: LogLevel = .error,
                useAsyncLogging: Bool = false,
                usingDateFormat dateFormat: String = LoggerBase.STANDARD_DATE_FORMAT,
                loggingKeys: [String] = JSONFileLogger.DEFAULT_LOGGING_KEYS,
                keyMapping: [String: String] = JSONFileLogger.DEFAULT_KEY_MAPPING) {
        
        self.encoding = encoding
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = dateFormat
        self.loggingKeys = loggingKeys
        self.keyMapping = keyMapping
        
        super.init(usingFile: file, rollover: rollover, logQueueName: logQueueName, withlogLevel: logLevel , useAsyncLogging: useAsyncLogging)
    }
    
    
    private func getMappedName(_ key: String) -> String {
        guard let name = self.keyMapping[key] else { return key }
        return name
     }
    
    
    internal override func logInfo(_ info: LoggerBase.LogInfo) {
        
        func sortKeys(lhs: String, rhs: String) -> Bool {
            func sortNumericValue(_ key: String) -> Int {
                switch getMappedName(key) {
                    case "date": return 0
                    case "level", "level_name","level_STDName", "level_symbol": return 1
                    case "message": return 100
                    default: return 50
                }
            }
            let iLhs = sortNumericValue(lhs)
            let iRhs = sortNumericValue(rhs)
            if iLhs < iRhs { return true }
            else if iLhs > iRhs { return false }
            else { return lhs < rhs }
            
            
            
        }
        
        var keyedData = info.dictionary(usingDateFormat: dateFormatter)
        keyedData["log_level_name"] = info.level.name
        keyedData["log_level_STDName"] = info.level.STDName
        keyedData["log_level_symbol"] = info.level.symbol
        //Must remove any objects that are not suposed to be logged
        for k in keyedData.keys {
            if !self.loggingKeys.contains(k) {
                keyedData.removeValue(forKey: k)
            }
        }
        
        var line: String = ""
        
        for k in keyedData.keys.sorted(by: sortKeys) {
            guard let obj = keyedData[k] else { continue }
            if !line.isEmpty { line += ", " }
            line += "\"\(self.getMappedName(k))\": "
            if let v = obj {
                if let _ = v as? NSNumber {
                    line += "\(v)"
                } else {
                    let s = "\(v)"
                    // escape double quotes and new lines
                    let msgEscapped = s.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\\n")
                    line += "\"\(msgEscapped)\""
                }
                
            } else {
                line += "null"
            }
        }
        
        line = ",\n{ " + line + " }\n]"
        
        guard var data = line.data(using: self.encoding, allowLossyConversion: false) else {
            
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
            if let fileHandle = FileHandle(forUpdatingAtPath: self.file) {
                fileHandle.seekToEndOfFile()
                
                guard let encClosingBrace = "\n]".data(using: self.encoding, allowLossyConversion: false) else {
                    self.triggerError(Error.unableToCovertStringToData(line))
                    return
                }
                if fileHandle.offsetInFile > encClosingBrace.count {
                    fileHandle.seek(toFileOffset: fileHandle.offsetInFile - UInt64(encClosingBrace.count))
                }
                repeat {
                    let dta = fileHandle.readData(ofLength: encClosingBrace.count)
                    if dta == encClosingBrace {
                        fileHandle.seek(toFileOffset: fileHandle.offsetInFile - UInt64(encClosingBrace.count))
                        break
                    }
                    else {
                        fileHandle.seek(toFileOffset: fileHandle.offsetInFile - 1)
                    }
                } while ( fileHandle.offsetInFile > encClosingBrace.count + 1)
                
                
                if fileHandle.offsetInFile == 0 {
                    let newStr: String = "[\n" + String(line.suffix(line.count - 2))
                    guard let dta = newStr.data(using: self.encoding, allowLossyConversion: false) else {
                        
                        self.triggerError(Error.unableToCovertStringToData(line))
                        return
                    }
                    
                    data = dta
                }
                
                
                fileHandle.write(data)
                fileHandle.closeFile()
            }
            else {
                self.triggerError(Error.unableToOpenFile(self.file))
            }
        } else {
            do {
                let newStr: String = "[\n" + String(line.suffix(line.count - 2))
                guard let data = newStr.data(using: self.encoding, allowLossyConversion: false) else {
                    
                    self.triggerError(Error.unableToCovertStringToData(line))
                    return
                }
                try data.write(to: fileURL, options: .atomic)
            } catch {
                self.triggerError(Error.unableToCreateFile(self.file))
            }
        }
        
        
        
    }
    

}
