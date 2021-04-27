import Foundation



/// Protocol for defining a logging object.
/// When supporting logging within an object, please store reference as this protocol instead of concreate logger type.
/// That way the actaul logger is interchangeable, and new logger types can be created and used down the road with no change to the objects
public protocol Logger {
    
    func canLog(_ level: LogLevel) -> Bool
    /// Log a message.  Do not call this method directly.  This is outlined so that concrete types that implement Logger have this method.
    /// Instead, please call the log(messaeg, level) helper method insetad.
    ///
    /// - parameters:
    ///     - message: The message to log
    ///     - level: The log level to use
    ///     - filename: The name of the file this is being called from
    ///     - line: The line number in the file that this method was called
    ///     - funcname: The name of the function that called this function
    ///     - additionalInfo: Any additional info to pass to the logger for use in the logging message
    func logMessage(message: String,
                    level: LogLevel,
                    filename: String,
                    line: Int,
                    funcname: String,
                    additionalInfo: [String: Any])
    
    /// Log a message.  Do not call this method directly.  This is outlined so that concrete types that implement Logger have this method.
    /// Instead, please call the log(messaeg, level) helper method insetad.
    ///
    /// - parameters:
    ///     - message: The message to log
    ///     - level: The log level to use
    ///     - source: The source where the log message originated from
    ///     - filename: The name of the file this is being called from
    ///     - line: The line number in the file that this method was called
    ///     - funcname: The name of the function that called this function
    ///     - additionalInfo: Any additional info to pass to the logger for use in the logging message
    func logMessage(message: String,
                    level: LogLevel,
                    source: String,
                    filename: String,
                    line: Int,
                    funcname: String,
                    additionalInfo: [String: Any])
}

public extension Logger {
    /// For backwards compatibility we provide a default logMessage which includes source so old code does not break.
    /// For new implementations we suggest providing yoru own method of this to property capure the source
    func logMessage(message: String,
                    level: LogLevel,
                    source: String,
                    filename: String,
                    line: Int,
                    funcname: String,
                    additionalInfo: [String: Any]) {
        // Adding a way to capture the source parameter later
        Thread.current.currentLoggerSource = source
        let oldSource = Thread.current.currentLoggerSource
        defer {
            Thread.current.currentLoggerSource = oldSource
        }
        self.logMessage(message: message,
                        level: level,
                        filename: filename,
                        line: line,
                        funcname: funcname,
                        additionalInfo: additionalInfo)
        
    }
}
public extension Logger {
#if swift(>=5.3)
    /// Log a message.  This calls the logMessage method on the instance of the logger.
    /// Never log with a log level of any.  Its not supported
    ///
    /// - parameters:
    ///    - message: The message to log
    ///    - level: The log level to use
    ///    - fileID: The file ID of the calling code (Defaults to #fileID)
    ///    - filename: The name of the file this is being called from (Defaults to #filePath)
    ///    - line: The line number in the file that this method was called (Defaults to #line)
    ///    - funcname: The name of the function that called this function (Defaults to #function)
    ///    - additionalInfo: Any additional info to pass to the logger for use in the logging message
    func log(_ message: String,
            _ level: LogLevel = .info,
            fileID: String = #fileID,
            filename: String = #filePath,
            line: Int = #line,
            funcname: String = #function,
            additionalInfo: [String: Any] = [:]) {
        precondition(level != .any, "Log level any should not be used when logging message.  It should only be used on logger objects as to the level in which to log")
        
        var source = fileID
        if let r = (source.range(of: "/") ?? source.range(of: "\\")) {
            source = String(source[..<r.lowerBound])
        }
        Thread.current.currentLoggerSource = source
        let oldSource = Thread.current.currentLoggerSource
        defer {
            Thread.current.currentLoggerSource = oldSource
        }
        self.logMessage(message: message,
                        level: level,
                        source: source,
                        filename: filename,
                        line: line,
                        funcname: funcname,
                        additionalInfo: additionalInfo)
    }
#else
    /// Log a message.  This calls the logMessage method on the instance of the logger.
    /// Never log with a log level of any.  Its not supported
    ///
    /// - parameters:
    ///    - message: The message to log
    ///    - level: The log level to use
    ///    - filename: The name of the file this is being called from (Defaults to #file)
    ///    - line: The line number in the file that this method was called (Defaults to #line)
    ///    - funcname: The name of the function that called this function (Defaults to #function)
    ///    - additionalInfo: Any additional info to pass to the logger for use in the logging message
    func log(_ message: String,
            _ level: LogLevel = .info,
            filename: String = #file,
            line: Int = #line,
            funcname: String = #function,
            additionalInfo: [String: Any] = [:]) {
        precondition(level != .any, "Log level any should not be used when logging message.  It should only be used on logger objects as to the level in which to log")
        #if os(Windows)
        let pathComponentSeparator = "\\"
        #else
        let pathComponentSeparator = "/"
        #endif
        var source = "N/A"
        let stack: [Thread.StackSymbol] = Thread.callStack
       
        let sourceComponent = "\(pathComponentSeparator)Sources\(pathComponentSeparator)"
        let testsComponent = "\(pathComponentSeparator)Tests\(pathComponentSeparator)"
        if stack.count > 1 {
            source = stack[1].module
        } else if let sourceStart = (filename.range(of: sourceComponent, options: .backwards) ?? filename.range(of: testsComponent, options: .backwards)) {
            // Try and find swift package name from folder directly under (Sources/Tests)
            if let packageStart = filename.range(of: pathComponentSeparator,
                                                 range: sourceStart.upperBound..<filename.endIndex) {
                
                source = String(filename[sourceStart.upperBound..<packageStart.lowerBound])
                
            // Try and find project name from parent folder of Sources/Tests
            } else if let projectStart = filename.range(of: pathComponentSeparator,
                                                        options: .backwards,
                                                        range: filename.startIndex..<sourceStart.lowerBound) {
                source = String(filename[projectStart.upperBound..<sourceStart.lowerBound])
            }
        }
        
        Thread.current.currentLoggerSource = source
        let oldSource = Thread.current.currentLoggerSource
        defer {
            Thread.current.currentLoggerSource = oldSource
        }
        self.logMessage(message: message,
                        level: level,
                        source: source,
                        filename: filename,
                        line: line,
                        funcname: funcname,
                        additionalInfo: additionalInfo)
    }
#endif
}
