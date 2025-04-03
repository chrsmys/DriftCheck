//
//  ExceptionBehavior.swift
//  DriftCheck
//
//  Created by Chris Mays on 3/26/25.
//

import Foundation
import IssueReporting

/**
    The behavior that is performed when a DriftReport exception is fired.
 */
public enum ExceptionBehavior {
    /// Logs the exception to the console.
    case log
    /// Triggers an assertionFailure
    case assert
    /// Hits a breakpoint
    case breakpoint
    /// Triggers a runtime warning in Xcode.
    case runtimeWarning
    /// Performs a custom action. This can be useful for visual debugging through toasts or
    /// or silently logging exceptions in production
    /// - Parameter behavior: The action that should occur when an exception is fired.
    case custom(_ behavior: (DriftCheckException)->Void)
    
    func handleResult(result: DriftCheckException,
                      fileID: StaticString = #fileID,
                      filePath: StaticString = #filePath) {
        switch self {
        case .log:
            print(result.message)
        case let .custom(block):
            block(result)
        case .breakpoint, .runtimeWarning, .assert:
            if let reporter = issueReporter {
                withIssueReporters([reporter], operation: {
                    if result.anchorItem.retained {
                        reportIssue("⚓️ Anchor remained past retention plan", fileID: fileID, filePath: filePath)
                    } else {
                        reportIssue("🛟 Object drifted away")
                    }
                })
            }
        }
    }
    
    private var issueReporter: IssueReporter? {
        switch self {
        case .assert:
            return .fatalError
        case .breakpoint:
            return .breakpoint
        case .runtimeWarning:
            return .runtimeWarning
        case .custom, .log:
            return nil
        }
    }
}
