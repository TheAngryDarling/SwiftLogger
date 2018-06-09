import XCTest
import Foundation
@testable import Logger


final class LoggerTests: XCTestCase {
    func testLogToConsole() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        print("Log Level: \(consoleLogger.logLevel.name)")
        consoleLogger.log("ERROR MESSAGE", .error)
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

    static var allTests = [
        ("testLogToConsole", testLogToConsole),
        ("testTextLogToFileDate", testTextLogToFileDate),
        ("testTextLogToFileSequence", testTextLogToFileSequence),
        ("testJSONLogToFileDate", testJSONLogToFileDate),
        ("testJSONLogToFileSequence", testJSONLogToFileSequence),
    ]
}
