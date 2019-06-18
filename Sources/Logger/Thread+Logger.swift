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
        #if os(Linux) && !swift(>=4.1)
        return [] //Currently not supported
        #else
        return callStackSymbols
        #endif
    }
}

