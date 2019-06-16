import Foundation



/// Protocol for defining a logging object.
/// When supporting logging within an object, please store reference as this protocol instead of concreate logger type.
/// That way the actaul logger is interchangeable, and new logger types can be created and used down the road with no change to the objects
public protocol Logger {
    
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
}

public extension Logger {
    
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
    public func log(_ message: String,
                    _ level: LogLevel = .info,
                    filename: String = #file,
                    line: Int = #line,
                    funcname: String = #function,
                    additionalInfo: [String: Any] = [:]) {
        precondition(level != .any, "Log level any should not be used when logging message.  It should only be used on logger objects as to the level in which to log")
        self.logMessage(message: message, level: level, filename: filename, line: line, funcname: funcname, additionalInfo: additionalInfo)
    }
}
