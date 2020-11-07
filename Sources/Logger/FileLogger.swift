//
//  FileLogger.swift
//  Logger
//
//  Created by Tyler Anger on 2018-06-09.
//

import Foundation
#if os(Linux)
import Dispatch
import Glibc
#endif

public extension FileLogger {
    enum Error: Swift.Error {
        case unableToOpenFile(String)
        case unableToCreateFile(String)
        case unableToCovertStringToData(String)
        case noAvailableStorage
    }
}


public extension FileLogger {
    /// Enum to indicate how file rollover names should be handled
    enum RolloverNaming: ExpressibleByStringLiteral {
        case sequential
        case sequentialWith(maxLogFiles: UInt)
        case date(format: String, maxLogFiles: UInt?)
        
        /// Creates a new Date rollover with the string as the format with now max log size
        public init(stringLiteral value: String) {
            self = .date(format: value, maxLogFiles: nil)
        }
        
        /// Creates a new sequential rollover
        public init() {
            self = .sequential
        }
        public init(sequentialUsingMaxLogFiles max: UInt) {
            self = .sequentialWith(maxLogFiles: max)
        }
        
        public init(dateFormat format: String, usingMaxLogFiles max: UInt? = nil) {
            self = .date(format: format, maxLogFiles: max)
        }
        
        /// Function to rollover the log file
        ///
        /// - Parameter path: The path of the file to rollover
        fileprivate func rolloverFile(atPath path: String) throws {
            switch self {
            case .sequential: try rolloverBySequence(atPath: path, withMaxLogs: nil)
            case .sequentialWith(maxLogFiles: let m): try rolloverBySequence(atPath: path, withMaxLogs: m)
            case .date(format: let f, maxLogFiles: let m): try rolloverByDate(atPath: path, dateFormat: f, withMaxLogs: m)
            }
        }
        
        
        /// Function to rollover the log file
        ///
        /// - Parameters:
        ///   - path: The path of the file to rollover
        ///   - format: The Date format string
        ///   - withMaxLogs: The count of the maximum number of log file to store if there is one
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
        
        /// Function to rollover the log file
        ///
        /// - Parameters:
        ///   - path: The path of the file to rollover
        ///   - withMaxLogs: The count of the maximum number of log file to store if there is one
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
    /// Indicates how to handle log file rolling over
    enum FileRollover {
        
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


/// Create new logger writting logs to specific file.
/// Only logs messages with a log level score >= log level in the logger will be written
public class FileLogger: LoggerBase {
    
    
    private struct LogFileDispatchQueueContainer {
        private let queue: DispatchQueue
        public private(set) var lastAccessed: Date
        public let file: String
        
        public init(forFile path: String) {
            self.file = path
            self.queue = DispatchQueue(label: "org.logger.FileLogger.FileDispatchQueue." + path)
            self.lastAccessed = Date()
        }
        
        public mutating func getQueue() -> DispatchQueue {
            self.lastAccessed = Date()
            return self.queue
        }
    }
    
    private static var LOG_FILE_QUEUE_LIST: [LogFileDispatchQueueContainer] = []
    private static let LOG_FILE_QUEUE_LIST_ACCESSOR: DispatchQueue = DispatchQueue(label: "org.logger.FileLogger.FileDispatchQueue.accessor")
   
    private static let LOG_FILE_QUEUE_LIST_CLEANER_TIMEOUT: TimeInterval = (60 * 60) // 1h - How old the dispatch queue can be idle for before its removed
    private static let LOG_FILE_QUEUE_LIST_CLEANER_TIMER_INTERVAL: TimeInterval = (60 * 15) // 15 minutes
    private static var LOG_FILE_QUEUE_LIST_CLEANER_LAST_EXECUTION: Date = Date()
    private static let LOG_FILE_QUEUE_LIST_CLEANER: Timer? = {
        if #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
            return Timer(timeInterval: LOG_FILE_QUEUE_LIST_CLEANER_TIMER_INTERVAL, repeats: true, block: FileLogger.fileQueueCleaner)
        } else {
            return nil
        }
    }()
    
    public var logLevel: LogLevel
    public var rollover: FileRollover
    public private(set) var file: String
    public var errorHandler: ((Swift.Error)->Void)? = nil
    
    public var pendingLogCount: Int { return self.loggerQueue.operationCount }
    
    
    /// Create new instance of FileLogger
    ///
    /// Note: This is an abstract class.  Must be inherited for use
    /// - Parameters:
    ///   - file: The file to write the logs to
    ///   - rollover: Indicates if and when to roll over files (Default: .none)
    ///   - logQueueName: The name of the queue used for logging (Default: nil)
    ///   - logLevel: The starting level for this logger (Default: .error)
    ///   - useAsyncLogging: Indicator if logging should be done asynchronously or synchronously (Default: false)
    public init(usingFile file: String,
                rollover: FileRollover = .none,
                logQueueName: String? = nil,
                withlogLevel logLevel: LogLevel = .error,
                useAsyncLogging: Bool = false) {
        self.logLevel = logLevel
        self.file = FileLogger.resolvePath(file)
        self.rollover = rollover
        super.init(logQueueName: logQueueName, useAsyncLogging: useAsyncLogging)
        
        precondition(type(of: self) != FileLogger.self,
                     "Can not initiate abstract class FileLogger.  Please use class that inherits it.")
    }
    
    
    /// Resolves any tilde in path and symbolic links.
    /// We want the real absolute path for the Global LogFileQueue to work properly
    /// Otherwise access to the same file from different logger objects could occur at the same time.
    private static func resolvePath(_ path: String) -> String {
        var rtn: String = path
        
        rtn = NSString(string: rtn).expandingTildeInPath
        rtn = NSString(string: rtn).resolvingSymlinksInPath
        
        return rtn
    }
    
    private static func fileQueueCleanerNoLocking() {
        FileLogger.LOG_FILE_QUEUE_LIST_CLEANER_LAST_EXECUTION = Date()
        for r in FileLogger.LOG_FILE_QUEUE_LIST {
            let dateDiff = FileLogger.LOG_FILE_QUEUE_LIST_CLEANER_LAST_EXECUTION.timeIntervalSince(r.lastAccessed)
            if dateDiff >= FileLogger.LOG_FILE_QUEUE_LIST_CLEANER_TIMEOUT {
                if let idx = FileLogger.LOG_FILE_QUEUE_LIST.index(where: { $0.file == r.file }) {
                    FileLogger.LOG_FILE_QUEUE_LIST.remove(at: idx)
                }
            }
        }
    }
    
    private static func fileQueueCleanerLocking() {
        FileLogger.LOG_FILE_QUEUE_LIST_ACCESSOR.sync {
            FileLogger.fileQueueCleanerNoLocking()
        }
    }
    /// Used to clean up any old log file queues
    private static func fileQueueCleaner(_ timer: Timer) -> Void {
        FileLogger.fileQueueCleanerLocking()
    }
    /// Gets/Creates the queue specific to the file
    /// This allows for safe writing to a speciifc file by multiple FileLoggers
    /// - Returns: Returns the queue identified with the file
    private func getLogQueue() -> DispatchQueue {
        return FileLogger.LOG_FILE_QUEUE_LIST_ACCESSOR.sync {
            // If we don't have a timmer running for clearing out old queue's, we will do a manual check.
            if FileLogger.LOG_FILE_QUEUE_LIST_CLEANER == nil {
                if Date().timeIntervalSince(FileLogger.LOG_FILE_QUEUE_LIST_CLEANER_LAST_EXECUTION) >= FileLogger.LOG_FILE_QUEUE_LIST_CLEANER_TIMER_INTERVAL {
                    FileLogger.fileQueueCleanerNoLocking()
                }
            }
            
            //Try and find the file in the list of queues alread created
            for i in 0..<FileLogger.LOG_FILE_QUEUE_LIST.count {
                if FileLogger.LOG_FILE_QUEUE_LIST[i].file == self.file {
                    return FileLogger.LOG_FILE_QUEUE_LIST[i].getQueue()
                }
            }
            
            //Create a new queue for this file
            var rtn = LogFileDispatchQueueContainer(forFile: self.file)
            FileLogger.LOG_FILE_QUEUE_LIST.append(rtn)
            return rtn.getQueue()
        }
    }
    /// Check to see if the file nees to be folled over
    /// If it does then roll the file
    private func doRolloverCheck() throws {
        try self.rollover.rollover(atPath: self.file)
    }
    
    internal override func canLogLevel(forInfo info: LogInfo) -> Bool {
        return (info.level >= self.logLevel)
    }
    
    internal override func logLine(_ info: LoggerBase.LogInfo) {
        
        do {
        
            //Since we inherit LoggerBase we know that this method is only called through the OperationQueue one at a time.  So no need to sync lock the roll over method when doing file name lookup / renames.
            try doRolloverCheck()
            
            // We call the log line on a dispatch queue directly associated with the file name
            // that way if there are multiple FileLogger objects logging to the same file there is no overlapping
            try self.getLogQueue().sync { try logInfo(info) }
            
            
        } catch {
            triggerError(error)
        }
        
    }
    
    /// Writes the information to the file
    /// - Parameter info: The information to log to the file
    /// - Throws: <#description#>
    internal func logInfo(_ info: LoggerBase.LogInfo) throws {
        precondition(type(of: self) != LoggerBase.self,
                     "Can not call abstract method FileLogger.logInfo.  Please use class that inherits it.")
    }
    
    /// Calls the error handler asynchronously
    /// - Parameter error: The error to pass to the error handler
    internal func triggerError(_ error: Swift.Error) {
        if let handler = errorHandler {
            DispatchQueue.global().async {
                handler(error)
            }
        }
    }
    
}
