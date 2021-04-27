import XCTest
import Foundation
@testable import Logger


final class LoggerTests: XCTestCase {
    
    override class func setUp() {
         func cleanUpLogs(_ logs: [String], in path: String) {
            var logComponents: [[String]] = []
            for log in logs {
                if let r = log.range(of: ".", options: .backwards) {
                    var components: [String] = []
                    components.append(String(log[log.startIndex..<r.lowerBound]))
                    components.append(String(log[r.upperBound..<log.endIndex]))
                    logComponents.append(components)
                }
            }
            
            if logComponents.count > 0 {
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: path) {
                    for object in contents {
                        for components in logComponents {
                            if object.hasPrefix(components[0]) && object.hasSuffix(".\(components[1])") {
                                var fullObjectPath = path
                                if !path.hasSuffix("/") { fullObjectPath += "/" }
                                fullObjectPath += object
                                print("Deleting '\(object)'")
                                try? FileManager.default.removeItem(atPath: fullObjectPath)
                                break
                            }
                        }
                    }
                }
            }
        }
        
        super.setUp()
        
        let logFileNameBases = ["testsequencelog", "testdatelog", "testsequenceMultilog"]
        let logFileExts = ["log", "json"]
        var logFileNames: [String] = []
        for logFileName in logFileNameBases {
            for ext in logFileExts {
                logFileNames.append(logFileName + "." + ext)
            }
        }
        cleanUpLogs(logFileNames, in: "/tmp/")
    }
    func testLogToConsole() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        consoleLogger.logLevel = .info
        // change console print format to output the source/module
        consoleLogger.logFormatString = ConsoleLogger.LOG_FORMAT_WITH_SOURCE
        print("Log Level: \(consoleLogger.logLevel.name)")
        consoleLogger.log("ERROR MESSAGE", .info)
        print("AFTER LOG")
        fflush(stdout)
        
    }
    
    func logToFile(_ logger: Logger) {
        for i in 0..<1000 {
            
            logger.log("Logging message \(i)", .error)
        }
    }
    
    func testTextLogToFileSequence() {
        let fileName: String = "/tmp/testsequencelog.log"
        
        let fileLog = TextFileLogger(usingFile: fileName,
                                     rollover: FileLogger.FileRollover(atSize: 1000, naming: .sequentialWith(maxLogFiles: 2)),
                                     withLogFormat: TextFileLogger.LOG_FORMAT_WITH_SOURCE)
        
        logToFile(fileLog)
        
    }
    
    
    func testTextLogToFileDate() {
        let fileName: String = "/tmp/testdatelog.log"
        
        let fileLog = TextFileLogger(usingFile: fileName,
                                 rollover: FileLogger.FileRollover(atSize: 1000, naming: "yyyy-MM-dd.HHmmssSSS"),
                                 withLogFormat: TextFileLogger.LOG_FORMAT_WITH_SOURCE)
        
        logToFile(fileLog)
    }
    
    func testJSONLogToFileSequence() {
        let fileName: String = "/tmp/testsequencelog.json"
        
        let fileLog = JSONFileLogger(usingFile: fileName,
                                 rollover: FileLogger.FileRollover(atSize: 1000, naming: .sequentialWith(maxLogFiles: 2)))
        
        logToFile(fileLog)
    }
    
    func testJSONLogToFileDate() {
        let fileName: String = "/tmp/testdatelog.json"
        
        let fileLog = JSONFileLogger(usingFile: fileName,
                                     rollover: FileLogger.FileRollover(atSize: 1000, naming: "yyyy-MM-dd.HHmmssSSS"))
        
        logToFile(fileLog)
    }
    
    func multiLogger(fileName: String, logLine: String) {
        
        let logger = TextFileLogger(usingFile: fileName,
                                     rollover: FileLogger.FileRollover(atSize: 100000, naming: .sequentialWith(maxLogFiles: 10)),
                                     withLogFormat: TextFileLogger.LOG_FORMAT_WITH_SOURCE)
        
        for i in 0..<10000 {
            
            logger.log(logLine + ": Logging message \(i)", .error)
        }
    }
    func testMultiLoggers() {
        let fileName: String = "/tmp/testsequenceMultilog.log"
        let opQueue: OperationQueue = OperationQueue()
        let queueCount = 4
        for i in 0..<queueCount {
            opQueue.addOperation {
                let s = Double((queueCount-1) - i) / 10000
                if s > 0.0 {
                    print("Queue [\(i)] sleeping for \(s)")
                    Thread.sleep(forTimeInterval: s)
                }
                self.multiLogger(fileName: fileName, logLine: "Logging Queue [\(i)]")
            }
        }
        opQueue.waitUntilAllOperationsAreFinished()
    }

    static var allTests = [
        ("testLogToConsole", testLogToConsole),
        ("testTextLogToFileDate", testTextLogToFileDate),
        ("testTextLogToFileSequence", testTextLogToFileSequence),
        ("testJSONLogToFileDate", testJSONLogToFileDate),
        ("testJSONLogToFileSequence", testJSONLogToFileSequence),
        ("testMultiLoggers", testMultiLoggers)
    ]
}
