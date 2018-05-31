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
    
    func testLogToFileDate() {
        let fileName: String = "/tmp/testdatelog.log"
        
        let fileLog = FileLogger(usingFile: fileName,
                                 rollover: FileLogger.FileRollover(atSize: 1000, naming: "yyyy-MM-dd.HHmmssSSS"))
        
        for i in 0..<1000 {
            
            fileLog.log("Logging message \(i)", .error)
        }
    }
    
    func testLogToFileSequence() {
        let fileName: String = "/tmp/testsequencelog.log"
        
        let fileLog = FileLogger(usingFile: fileName,
                                 rollover: FileLogger.FileRollover(atSize: 1000, naming: .sequentialWith(maxLogFiles: 2)))
        
        for i in 0..<1000 {
            
            fileLog.log("Logging message \(i)", .error)
        }
    }

    static var allTests = [
        ("testLogToConsole", testLogToConsole),
        //("testLogToFileDate", testLogToFileDate),
        ("testLogToFileSequence", testLogToFileSequence),
    ]
}
