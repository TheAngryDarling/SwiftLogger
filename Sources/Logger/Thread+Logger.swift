//
//  Thread+Logger.swift
//  Logger
//
//  Created by Tyler Anger on 2019-06-18.
//



import class Foundation.Thread
#if os(Linux) && !swift(>=4.1)
import func CoreFoundation._CFIsMainThread
#endif
internal extension Thread {
    struct StackSymbol {
        public let stack: String
        public let index: Int
        public let module: String
        public let address: UInt
        public let location: String
        public let locationOffset: UInt
        
        public init(_ string: String) {
            self.stack = string
            var string = string
            guard let endOfIndexIdx = string.firstIndex(of: " ") else {
                fatalError("Invalid Stack Symbol String '\(string)'")
            }
            guard let index = Int(String(string[string.startIndex..<endOfIndexIdx])) else {
                fatalError("Invalid stack index '\(string[string.startIndex..<endOfIndexIdx])' in '\(string)'")
            }
            self.index = index
            string = String(string[endOfIndexIdx...])
            while string.hasPrefix(" ") { string.removeFirst() }
            
            guard let endOfModuleIdx = string.firstIndex(of: " ") else {
                fatalError("Invalid Stack Symbol String '\(string)'")
            }
            
            self.module = String(string[string.startIndex..<endOfModuleIdx])
            string = String(string[endOfModuleIdx...])
            while string.hasPrefix(" ") { string.removeFirst() }
            
            guard let endOfAddressIdx = string.firstIndex(of: " ") else {
                fatalError("Invalid Stack Symbol String '\(string)'")
            }
            guard string.hasPrefix("0x") else {
                fatalError("Invalid Stack Symbol String '\(string)'")
            }
            
            guard let address = UInt(String(string[string.index(string.startIndex, offsetBy: 2)..<endOfAddressIdx]), radix: 16) else {
                fatalError("Invalid stack address '\(string[string.startIndex..<endOfAddressIdx])' in '\(string)'")
            }
            self.address = address
            string = String(string[endOfAddressIdx...])
            while string.hasPrefix(" ") { string.removeFirst() }
            
            
            guard let endOfLocationIdx = string.range(of: " + ")?.lowerBound else {
                fatalError("Invalid Stack Symbol String '\(string)'")
            }
            
            self.location = String(string[string.startIndex..<endOfLocationIdx])
            string = String(string[endOfLocationIdx...])
            guard let plusIdx = string.firstIndex(of: "+") else {
                fatalError("Invalid Stack Symbol String '\(string)'")
            }
            string = String(string[string.index(after: plusIdx)...])
            while string.hasPrefix(" ") { string.removeFirst() }
            
            guard let locationOffset = UInt(string) else {
                fatalError("Invalid stack address '\(string)'")
            }
            self.locationOffset = locationOffset
            
        }
    }
    // `isMainThread` is not implemented yet in swift-corelibs-foundation.
    static var _isMainThread: Bool {
        #if os(Linux) && !swift(>=4.1)
        return _CFIsMainThread()
        #else
        return isMainThread
        #endif
    }
    var _isMainThread: Bool {
        #if os(Linux) && !swift(>=4.1)
        return _CFIsMainThread()
        #else
        return isMainThread
        #endif
    }
    
    static var _callStackSymbols: [String] {
        #if !_runtime(_ObjC) && !swift(>=4.1)
            return [] //Currently not supported
        #else
            var stack = callStackSymbols
            // Remove first line as its from this method
            stack.remove(at: 0)
            #if _runtime(_ObjC)
                // Adjust the index of each line to reflect the removal of the first line
                for i in 0..<stack.count {
                    let current = i + 1
                    let strCurrent = "\(current)"
                    let strNew = "\(i)"
                    var working = stack[i]
                    working.removeFirst(strCurrent.count)
                    working = strNew + working
                    stack[i] = working
                }
            #endif
        
            return stack
        #endif
    }
    
    static var callStack: [StackSymbol] {
        #if _runtime(_ObjC)
        return self._callStackSymbols.map(StackSymbol.init)
        #else
        return []
        #endif
    }
    /// Storage for the current log message source module
    var currentLoggerSource: String? {
        get {
            return self.threadDictionary["Logger.Source"] as? String
        }
        set {
            self.threadDictionary["Logger.Source"] = newValue
        }
    }
}

