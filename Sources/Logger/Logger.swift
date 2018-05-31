import Foundation

public enum LogLevel: Int {
    case debug = 1
    case info = 2
    case warn = 3
    case error = 4
    case fatal = 5
    case none = 6
    
    public var name: String {
        switch self {
        case .info:
            return "info"
        case .debug:
            return "debug"
        case .warn:
            return "warn"
        case .error:
            return "error"
        case .fatal:
            return "fatal"
        case .none:
            return ""
        }
    }
    
    public var STDName: String { return self.name.uppercased() }
    public var symbol: String {
        switch self {
            case .info:
                return "ℹ️"
            case .debug:
                return "✳️"
            case .warn:
                return "⚠️"
            case .error:
                return "🚫"
            case .fatal:
                return "🆘"
            case .none:
                return ""
        }
    }
}

/**
 Protocol for defining a logging object.
 When supporting logging within an object, please store reference as this protocol instead of concreate logger type.
 That way the actaul logger is interchangeable, and new logger types can be created and used down the road with no change
 to the objects
*/
public protocol Logger {
    /*
     Log a message.  Do not call this method directly.  This is outlined so that concrete types that implement Logger have this method.
     Instead, please call the log(messaeg, level) helper method insetad.
     - parameters:
         - message: The message to log
         - level: The log level to use
         - filename: The name of the file this is being called from
         - line: The line number in the file that this method was called
         - funcname: The name of the function that called this function
     */
    func logMessage(message: String, level: LogLevel, filename: String, line: Int, funcname: String)
}

public extension Logger {
    /*
     Log a message.  This calls the logMessage method on the instance of the logger
     - parameters:
        - message: The message to log
        - level: The log level to use
        - filename: The name of the file this is being called from (Defaults to #file)
        - line: The line number in the file that this method was called (Defaults to #line)
        - funcname: The name of the function that called this function (Defaults to #function)
    */
    public func log(_ message: String,
                    _ level: LogLevel = .info,
                    filename: String = #file,
                    line: Int = #line,
                    funcname: String = #function) {
        self.logMessage(message: message, level: level, filename: filename, line: line, funcname: funcname)
    }
}

fileprivate class NilLogger: Logger {
    func logMessage(message: String, level: LogLevel, filename: String, line: Int, funcname: String) {
        //Do Nothing here
    }
}

//Global access to nil logger
public let nilLogger: Logger = NilLogger()


open class LoggerBase: Logger {
    
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
        
        public init(date: Date = Date(),
                    level: LogLevel,
                    message: String,
                    processIdentifier: Int32 = ProcessInfo.processInfo.processIdentifier,
                    processName: String = ProcessInfo.processInfo.processName,
                    thread: Thread = Thread.current,
                    filename: String,
                    line: Int,
                    funcname: String,
                    stackSymbols: [String] = Thread.callStackSymbols) {
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
        }
        
    }
    
    fileprivate var loggerQueue: OperationQueue
    private var useAsyncLogging: Bool
    
    public init(logQueueName: String?, useAsyncLogging: Bool = true) {
        self.loggerQueue = OperationQueue()
        self.loggerQueue.maxConcurrentOperationCount = 1 //Log one item at a time
        if let n = logQueueName { self.loggerQueue.name = n }

        self.useAsyncLogging = useAsyncLogging
        
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
    
   
    fileprivate func canLogLevel(_ level: LogLevel, forInfo info: LogInfo) -> Bool {
        precondition(type(of: self) != LoggerBase.self, "Can not call abstract method LoggerBase.canLogLevel.  Please use class that inherits it.")
        return false
    }
    
    
    public func logMessage(message: String,
                           level: LogLevel,
                           filename: String,
                           line: Int,
                           funcname: String) {
        
        let info = LogInfo(level: level,
                           message: message,
                           filename: filename,
                           line: line,
                           funcname: funcname)
        
         if self.canLogLevel(level, forInfo: info) {
            guard self.useAsyncLogging else {
                self.logLine(info)
                return
            }
            
            self.loggerQueue.addOperation {
                self.logLine(info)
            }
        }
    }

    fileprivate func logLine(_ info: LogInfo) {
         precondition(type(of: self) != LoggerBase.self, "Can not call abstract method LoggerBase.log.  Please use class that inherits it.")
    }
    
}


/**
 Used to log to the console.
 */
public class ConsoleLogger: LoggerBase {
    public var logLevel: LogLevel
    public var showEmojis: Bool = true
    public var useSTDNaming: Bool = false
    private let dateFormatter: DateFormatter
    
    public init(logQueueName: String? = nil,
                withlogLevel logLevel: LogLevel = .error,
                usingDateFormat dateFormat: String = "yyyy/MM/dd HH:mm:ss:SSS") {
        self.logLevel = logLevel
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = dateFormat
        super.init(logQueueName: logQueueName, useAsyncLogging: false)
    }
    
    fileprivate override func canLogLevel(_ level: LogLevel, forInfo info: LogInfo) -> Bool {
        return (UInt8(level.rawValue) >= self.logLevel.rawValue)
    }
    
    fileprivate override func logLine(_ info: LoggerBase.LogInfo) {
        let levelInfoSec: String = {
            var rtn: String = self.useSTDNaming ?  info.level.STDName : info.level.name
            if self.showEmojis { rtn = "(\(info.level.symbol))" + rtn }
            return rtn
        }()
        let threadName: String = info.threadName ?? "nil"
        
        
        let line = "[\(levelInfoSec)] [\(dateFormatter.string(from: info.date))] [\(info.processName):\(info.processIdentifier)] [\(threadName)] [\(info.filename):(\(info.line))] [\(info.funcname)]: \(info.message)"
        
        print(line)
        //Using fputs instead of print because sometines when using print the message gets broken up when another thread prints at the same time
        //fputs(line + "\n", stdout)
        fflush(stdout)
    }
}

//Global access to concole logger
public let consoleLogger: ConsoleLogger = ConsoleLogger()

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
open class FileLogger: LoggerBase {
    
    public var logLevel: LogLevel
    public var rollover: FileRollover
    private let encoding: String.Encoding
    private let dateFormatter: DateFormatter
    public private(set) var file: String
    public var asyncErrorHandler: ((Error)->Void)? = nil
    
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
                withStringEncoding encoding: String.Encoding = .utf8,
                logQueueName: String? = nil,
                withlogLevel logLevel: LogLevel = .error,
                usingDateFormat dateFormat: String = "yyyy-MM-dd HH:mm:ss:SSS") {
        self.logLevel = logLevel
        self.file = file
        self.rollover = rollover
        self.encoding = encoding
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = dateFormat
        super.init(logQueueName: logQueueName)
    }
    
    private func doRolloverCheck() throws {
        try self.rollover.rollover(atPath: self.file)
    }
    
    fileprivate override func canLogLevel(_ level: LogLevel, forInfo info: LogInfo) -> Bool {
        return (UInt8(level.rawValue) >= self.logLevel.rawValue)
    }
    
    fileprivate override func logLine(_ info: LoggerBase.LogInfo) {
        
        let threadName: String = info.threadName ?? "nil"
        var line: String = "\(dateFormatter.string(from: info.date)) - \(info.processName):\(info.processIdentifier) (\(threadName)) - \(info.level.STDName) - \(info.filename):\(info.line) - \(info.funcname) - \(info.message)"
        
        line += "\n"
        //Get Data
        guard let data = line.data(using: self.encoding, allowLossyConversion: false) else {
            
            if let f = asyncErrorHandler { f(Error.unableToCovertStringToData(line)) }
            else {
                //Print to std error
                fputs("Unable to convert line '\(line)' into data.\n", stderr)
                fflush(stderr)
            }
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
            if let f = self.asyncErrorHandler { f(Error.noAvailableStorage) }
            else {
                fputs("No storage to log to file '\(self.file)'.\n", stderr)
                fflush(stderr)
            }
            return
        }
        
        if FileManager.default.fileExists(atPath: self.file) {
            if let fileHandle = FileHandle(forWritingAtPath: self.file) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
            else {
                if let f = self.asyncErrorHandler { f(Error.unableToOpenFile(self.file)) }
                else {
                    //Print to std error
                    fputs("Unable to open file '\(self.file)' for writing: (\(errno).\n", stderr)
                    fflush(stderr)
                }
            }
        } else {
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                if let f = self.asyncErrorHandler { f(Error.unableToCreateFile(self.file)) }
                else {
                    //Print to std error
                    fputs("Unable to create file '\(self.file)' for writing: (\(errno).\n", stderr)
                    fflush(stderr)
                }
            }
        }
        
        //Since we inherit LoggerBase we know that this method is only called through the OperationQueue one at a time.  So no need to sync lock the roll over method when doing file name lookup / renames.
        try? doRolloverCheck()
        
    }
    
}



