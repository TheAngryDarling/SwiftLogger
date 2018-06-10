//
//  FileLogger.swift
//  Logger
//
//  Created by Tyler Anger on 2018-06-09.
//

import Foundation

public extension FileLogger {
    public enum Error: Swift.Error {
        case unableToOpenFile(String)
        case unableToCreateFile(String)
        case unableToCovertStringToData(String)
        case noAvailableStorage
    }
}


public extension FileLogger {
    public enum RolloverNaming: ExpressibleByStringLiteral {
        case sequential
        case sequentialWith(maxLogFiles: UInt)
        case date(format: String, maxLogFiles: UInt?)
        
        
        public init(stringLiteral value: String) {
            self = .date(format: value, maxLogFiles: nil)
        }
        
        public init() {
            self = .sequential
        }
        public init(sequentialUsingMaxLogFiles max: UInt) {
            self = .sequentialWith(maxLogFiles: max)
        }
        
        public init(dateFormat format: String, usingMaxLogFiles max: UInt? = nil) {
            self = .date(format: format, maxLogFiles: max)
        }
        
        fileprivate func rolloverFile(atPath path: String) throws {
            switch self {
            case .sequential: try rolloverBySequence(atPath: path, withMaxLogs: nil)
            case .sequentialWith(maxLogFiles: let m): try rolloverBySequence(atPath: path, withMaxLogs: m)
            case .date(format: let f, maxLogFiles: let m): try rolloverByDate(atPath: path, dateFormat: f, withMaxLogs: m)
            }
        }
        
        
        private func rolloverByDate(atPath path: String, dateFormat format: String, withMaxLogs: UInt?) throws {
            let nsFilename = NSString(string: path)
            var filename = nsFilename.deletingPathExtension
            
            let dtf = DateFormatter()
            dtf.dateFormat = format
            
            filename += "." + dtf.string(from: Date())
            filename += "." + nsFilename.pathExtension
            
            if !FileManager.default.fileExists(atPath: filename) {
                try FileManager.default.moveItem(atPath: path, toPath: filename)
            }
            else {
                let dta = try Data(contentsOf: URL(fileURLWithPath: path))
                if let fileHandle = FileHandle(forWritingAtPath: filename) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(dta)
                    fileHandle.closeFile()
                }
                else {
                    throw Error.unableToOpenFile(filename)
                }
            }
            
            if let maxLogs = withMaxLogs {
                let filenameOnly: String = nsFilename.lastPathComponent
                var parentDir = nsFilename.deletingLastPathComponent
                if !parentDir.hasSuffix("/") { parentDir += "/" }
                
                let filenameStart = NSString(string: NSString(string: filenameOnly).lastPathComponent).deletingPathExtension
                var files = try FileManager.default.contentsOfDirectory(atPath: parentDir).filter({ $0.hasPrefix(filenameStart) && !($0 == filenameOnly) }).sorted { lhs, rhs in
                    
                    func getDateFrom(fileName: String) -> Date? {
                        
                        var s = String(fileName.suffix(fileName.count - (filenameStart.count + 1)))
                        s = String(s.prefix(s.count - (nsFilename.pathExtension.count + 1)))
                        return dtf.date(from: s)
                        
                    }
                    
                    let ld = getDateFrom(fileName: lhs)
                    let rd = getDateFrom(fileName: rhs)
                    
                    if let l = ld, let r = rd { return (l < r) }
                    else if ld != nil && rd == nil { return true }
                    else if ld == nil && rd != nil { return false }
                    else { return lhs < rhs }
                    
                    
                }
                
                files.reverse()
                
                if files.count > (maxLogs - 1) {
                    let countToTrim = files.count - (Int(maxLogs) - 1)
                    for i in 0..<countToTrim {
                        try FileManager.default.removeItem(atPath: parentDir + files[i])
                    }
                }
            }
            
        }
        
        private func rolloverBySequence(atPath path: String, withMaxLogs: UInt?) throws {
            
            func getCurrentSequence(fromPath path: String) -> UInt? {
                //print("getCurrentSequence.CurrentPath: '\(path)'")
                let nsFilename = NSString(string: path)
                let nsFileNameWithoutExt = NSString(string: nsFilename.deletingPathExtension)
                let sSeq = nsFileNameWithoutExt.pathExtension
                //print("getCurrentSequence.return: '\(sSeq)'")
                return UInt(sSeq)
            }
            
            func nextSequenceFile(atPath path: String) -> String {
                //print("nextSequenceFile.CurrentPath: '\(path)'")
                let currentSequence = getCurrentSequence(fromPath: path) ?? 0
                let nextSequence = currentSequence + 1
                
                let nsFilename = NSString(string: path)
                var nsFileNameWithoutExt = NSString(string: nsFilename.deletingPathExtension)
                
                if currentSequence != 0 { nsFileNameWithoutExt = NSString(string: nsFileNameWithoutExt.deletingPathExtension) }
                //String(nsFileNameWithoutExt) <-- Does not work on linux.  Adding hack instead
                let rtn = nsFileNameWithoutExt.appending(".\(nextSequence).\(nsFilename.pathExtension)")
                //print("nextSequenceFile.return: '\(rtn)'")
                return rtn
            }
            
            func move(from: String, to: String) throws {
                if FileManager.default.fileExists(atPath: to) {
                    let newTo = nextSequenceFile(atPath: to)
                    try move(from: to, to: newTo)
                }
                try FileManager.default.moveItem(atPath: from, toPath: to)
            }
            
            try move(from: path, to: nextSequenceFile(atPath: path))
            
            
            if let maxLogs = withMaxLogs {
                let nsFilename = NSString(string: path)
                let filenameOnly: String = nsFilename.lastPathComponent
                var parentDir = nsFilename.deletingLastPathComponent
                if !parentDir.hasSuffix("/") { parentDir += "/" }
                
                let filenameStart = NSString(string: NSString(string: filenameOnly).lastPathComponent).deletingPathExtension
                var files = try FileManager.default.contentsOfDirectory(atPath: parentDir).filter({ $0.hasPrefix(filenameStart) && !($0 == filenameOnly) }).sorted { lhs, rhs in
                    
                    let lhsS = getCurrentSequence(fromPath: lhs)
                    let rhsS = getCurrentSequence(fromPath: rhs)
                    
                    if let l = lhsS, let r = rhsS { return (l < r) }
                    else if lhsS != nil && rhsS == nil { return true }
                    else if lhsS == nil && rhsS != nil { return false }
                    else { return lhs < rhs }
                    
                }
                files.reverse()
                
                if files.count > (maxLogs - 1) {
                    let countToTrim = files.count - (Int(maxLogs) - 1)
                    for i in 0..<countToTrim {
                        try FileManager.default.removeItem(atPath: parentDir + files[i])
                    }
                }
                
            }
            
        }
        
    }
}

public extension FileLogger {
    // Indicates how to handle log file rolling over
    public enum FileRollover {
        
        case none
        case atSize(UInt, naming: RolloverNaming)
        case eachDay(naming: RolloverNaming)
        case eachHour(naming: RolloverNaming)
        case custom(()->Bool, naming: RolloverNaming)
        
        public init() { self = .none }
        public init(atSize size: UInt, naming: RolloverNaming) { self = .atSize(size, naming: naming) }
        public init(eachDay naming: RolloverNaming) { self = .eachDay(naming: naming) }
        public init(eachHour naming: RolloverNaming) { self = .eachHour(naming: naming) }
        public init(custom: @autoclosure @escaping () -> Bool, naming: RolloverNaming) {
            self = .custom(custom, naming: naming)
        }
        
        fileprivate func rollover(atPath path: String) throws {
            switch self {
            case .atSize(let sz, naming: let n): try rolloverBySize(atPath: path, withMaxSize: sz, usingNaming: n)
            case .eachDay(naming: let n): try rolloverByDay(atPath: path, usingNaming: n)
            case .eachHour(naming: let n): try rolloverByHour(atPath: path, usingNaming: n)
            case .custom(let c, naming: let n): try rolloverByCustom(atPath: path, usingCustom: c, usingNaming: n)
            case .none: break
            }
            
        }
        
        private func rolloverBySize(atPath path: String, withMaxSize size: UInt, usingNaming naming: RolloverNaming) throws {
            guard FileManager.default.fileExists(atPath: path) else { return }
            //Skip errors and just exit
            guard let attr = try? FileManager.default.attributesOfItem(atPath: path) else { return }
            //print("Got attrs [\(FileAttributeKey.size.rawValue)])")
            //guard let sz =  attr[FileAttributeKey.size] else { return }
            //print("sz: \(sz), type: \(type(of: sz)), asInt64: \(sz as? Int)")
            guard let nsFileSize = attr[FileAttributeKey.size] as? NSNumber else { return }
            guard let fileSize = UInt(exactly: nsFileSize) else { return }
            //print("Got Size")
            //print("FileSize: \(fileSize), RollOverSize: \(size): Should Rollover: \(fileSize >= size)")
            guard fileSize >= size else { return }
            
            try naming.rolloverFile(atPath: path)
        }
        
        private func rolloverByDay(atPath path: String, usingNaming naming: RolloverNaming) throws {
            guard FileManager.default.fileExists(atPath: path) else { return }
            guard let attr = try? FileManager.default.attributesOfItem(atPath: path) else { return }
            guard let modDate = attr[FileAttributeKey.modificationDate] as? Date else { return }
            let currentDate = Date()
            
            let calendar = Calendar.current
            let modYear = calendar.component(.year, from: modDate)
            let modMonth = calendar.component(.month, from: modDate)
            let modDay = calendar.component(.day, from: modDate)
            
            let curYear = calendar.component(.year, from: currentDate)
            let curMonth = calendar.component(.month, from: currentDate)
            let curDay = calendar.component(.day, from: currentDate)
            
            guard (modYear == curYear && modMonth == curMonth && modDay == curDay) else { return }
            
            try naming.rolloverFile(atPath: path)
            
        }
        
        private func rolloverByHour(atPath path: String, usingNaming naming: RolloverNaming) throws {
            guard FileManager.default.fileExists(atPath: path) else { return }
            guard let attr = try? FileManager.default.attributesOfItem(atPath: path) else { return }
            guard let modDate = attr[FileAttributeKey.modificationDate] as? Date else { return }
            let currentDate = Date()
            
            let calendar = Calendar.current
            let modYear = calendar.component(.year, from: modDate)
            let modMonth = calendar.component(.month, from: modDate)
            let modDay = calendar.component(.day, from: modDate)
            let modHour = calendar.component(.hour, from: modDate)
            
            let curYear = calendar.component(.year, from: currentDate)
            let curMonth = calendar.component(.month, from: currentDate)
            let curDay = calendar.component(.day, from: currentDate)
            let curHour = calendar.component(.hour, from: currentDate)
            
            guard (modYear == curYear && modMonth == curMonth && modDay == curDay && modHour == curHour) else { return }
            
            try naming.rolloverFile(atPath: path)
        }
        
        private func rolloverByCustom(atPath path: String, usingCustom: () -> Bool, usingNaming naming: RolloverNaming ) throws {
            if usingCustom() {
                try naming.rolloverFile(atPath: path)
            }
        }
    }
}


/**
 Create new logger writting logs to specific file.
 */
public class FileLogger: LoggerBase {
    
    public var logLevel: LogLevel
    public var rollover: FileRollover
    public private(set) var file: String
    public var errorHandler: ((Swift.Error)->Void)? = nil
    
    public var pendingLogCount: Int { return self.loggerQueue.operationCount }
    
    /**
     Create new instance of FileLogger
     - parameters:
     - usingFile: The file to write the logs to
     - rollover: Indicates if and when to roll over files (Default is .none)
     - logQueueName: The name of the queue used for logging (Default is nil)
     - withLogLevel: The starting level for this logger (Default is .error)
     - usingDateFormat: Date format for date used in log file (Default is 'yyyy-MM-dd HH:mm:ss:SSS')
     */
    public init(usingFile file: String,
                rollover: FileRollover = .none,
                logQueueName: String? = nil,
                withlogLevel logLevel: LogLevel = .error,
                useAsyncLogging: Bool = false) {
        self.logLevel = logLevel
        self.file = file
        self.rollover = rollover
        super.init(logQueueName: logQueueName, useAsyncLogging: useAsyncLogging)
    }
    
    private func doRolloverCheck() throws {
        try self.rollover.rollover(atPath: self.file)
    }
    
    internal override func canLogLevel(_ level: LogLevel, forInfo info: LogInfo) -> Bool {
        return (level >= self.logLevel)
    }
    
    internal override func logLine(_ info: LoggerBase.LogInfo) {
        
        
        do {
        
            //Since we inherit LoggerBase we know that this method is only called through the OperationQueue one at a time.  So no need to sync lock the roll over method when doing file name lookup / renames.
            try doRolloverCheck()
        } catch {
            triggerError(error)
        }
        
    }
    
    internal func triggerError(_ error: Swift.Error) {
        if let handler = errorHandler {
            DispatchQueue.global().async {
                handler(error)
            }
        }
    }
    
}