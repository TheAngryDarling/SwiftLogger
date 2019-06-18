import XCTest
import Foundation
@testable import Logger


final class LoggerTests: XCTestCase {
    
    override class func setUp() {
        super.setUp()
        try? FileManager.default.removeItem(atPath: "/tmp/testsequencelog.log")
        try? FileManager.default.removeItem(atPath: "/tmp/testdatelog.log")
        try? FileManager.default.removeItem(atPath: "/tmp/testsequencelog.json")
        try? FileManager.default.removeItem(atPath: "/tmp/testdatelog.json")
        try? FileManager.default.removeItem(atPath: "/tmp/testsequenceMultilog.log")
    }
    func testLogToConsole() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        consoleLogger.logLevel = .info
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
                                     rollover: FileLogger.FileRollover(atSize: 1000, naming: .sequentialWith(maxLogFiles: 2)))
        
        logToFile(fileLog)
        
    }
    
    
    func testTextLogToFileDate() {
        let fileName: String = "/tmp/testdatelog.log"
        
        let fileLog = TextFileLogger(usingFile: fileName,
                                 rollover: FileLogger.FileRollover(atSize: 1000, naming: "yyyy-MM-dd.HHmmssSSS"))
        
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
                                     rollover: FileLogger.FileRollover(atSize: 100000, naming: .sequentialWith(maxLogFiles: 10)))
        
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
