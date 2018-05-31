# Logger
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

Simple protocol (Logger) to define and use logging.
There are two concreate implementations of the Logger protocol (ConsoleLogger, FileLogger)

## Usage
Creating new instances of the FileLogger:
```Swift
let fileLogger = FileLogger(usingFile: "logfile.log", withlogLevel: .info)
fileLogger.log("Error Message", .error)
```
Accessing the Console Logger: 
```Swift
    //consoleLogger is a global instance of the ConsoleLogger class that is already initialized.
    consoleLogger.log("message", .info)
```

When using in other object of logging:
```Swift
class Object {
    var logger: Logger?
    
    public func doMethod() {
        ...
        logger?.log("Doing doMethod", .info)
    }
}

let obj = Object()
obj.logger = consoleLogger
consoleLogger.logLevel = .info
obj.doMethod()
```

## Authors

* **Tyler Anger** - *Initial work* - [TheAngryDarling](https://github.com/TheAngryDarling)

## License

This project is licensed under Apache License v2.0 - see the [LICENSE.md](LICENSE.md) file for details
