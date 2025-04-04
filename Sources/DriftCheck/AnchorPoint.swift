//
//  AnchorPoint.swift
//  RetainDetector
//
//  Created by Chris Mays on 3/24/25.
//

import UIKit

/// An object that can be tethered to and is monitored for deallocation based on it's retentionMode.
public protocol AnchorPoint: NSObject {
    /// Attaches an object to an anchor and ensures the attached object is
    /// deallocated along with the anchor.
    @MainActor func tether(_ obj: AnyObject)
}

protocol PrivateAnchorPoint: AnchorPoint {
    @MainActor func isInHierarchy() -> Bool
    @MainActor func children() -> [PrivateAnchorPoint]
    @MainActor func prepareToCheckStatus() -> Void
}

@MainActor
extension AnchorPoint {
    
    package var anchorId: String {
        hexAddress(self)
    }
    
    package var isAppleType: Bool {
        guard let bundleID = Bundle(for: type(of: self)).bundleIdentifier else {
            return false
        }
        return bundleID.hasPrefix("com.apple.")
    }
    
    @MainActor
    package var driftReporter: DriftReporter {
        get {
            objc_getAssociatedObject(self, &AnchorPointAssociatedKeys.driftReporterKey) as? DriftReporter ?? DriftReporter.shared
        }
        set {
            objc_setAssociatedObject(self, &AnchorPointAssociatedKeys.driftReporterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Explicitly sets the retentionMode on an anchor. If not set then it will use the value
    /// from DriftReporter's retentionPlan.
    @MainActor
    public var retentionMode: RetentionMode {
        get {
            driftReporter.retentionModeOverrides[anchorId] ?? driftReporter.retentionPlan(self)
        }
        set {
            driftReporter.retentionModeOverrides[anchorId] = newValue
        }
    }
}

@MainActor
extension PrivateAnchorPoint {
    
    @MainActor
    public func tether(_ obj: AnyObject) {
        driftReporter.tether(obj, to: self)
        setDeinitDetector()
    }
    
    @MainActor
    func untether(_ obj: AnyObject) {
        driftReporter.untether(obj, from: self)
    }
    
    func updateStatus(retentionMode: RetentionMode) {
        guard retentionMode != .optOut else {
            deinitDetector?.decommission()
            deinitDetector = nil
            ensureChildrenNotified()
            return
        }
        let anchorId = self.anchorId
        guard driftReporter.currentEvaluations.contains(anchorId) == false else {
            return
        }
        self.driftReporter.currentEvaluations.insert(anchorId)
        let anchorType = String(describing: type(of: self))
        let waiter = FrameWaiter()
        let driftReporter = driftReporter
        switch self.retentionMode {
        case let .onRemovalFromHierarchy(frames):
            deinitDetector?.decommission()
            deinitDetector = nil
            self.ensureChildrenNotified()
            waiter.wait(frames: frames) { @MainActor [weak self] in
                if self?.isInHierarchy() != true {
                    driftReporter.checkForDrift(self, anchorId: anchorId, anchorType: anchorType)
                }
            }
        case .onDealloc:
            setDeinitDetector()
        case .optOut:
            break
        }
    }
    
    func ensureChildrenNotified() {
        children().forEach {
            $0.prepareToCheckStatus()
            $0.ensureChildrenNotified()
        }
    }
    
    @MainActor
    func setDeinitDetector() {
        let waiter = FrameWaiter()
        let anchorId = self.anchorId
        let anchorType = String(describing: type(of: self))
        let driftReporter = driftReporter
        deinitDetector?.decommission()
        deinitDetector = .init { [weak self] in
            self?.ensureChildrenNotified()
            waiter.wait(frames: 1) { @MainActor [weak self] in
                driftReporter.checkForDrift(self, anchorId: anchorId, anchorType: anchorType)
            }
        }
    }
}

extension PrivateAnchorPoint {
    var deinitDetector: DeinitDetector? {
        get {
            objc_getAssociatedObject(self, &AnchorPointAssociatedKeys.leakAnchorKey) as? DeinitDetector
        }
        set {
            objc_setAssociatedObject(self, &AnchorPointAssociatedKeys.leakAnchorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension PrivateAnchorPoint where Self: UIResponder {
    @MainActor
    func isInHierarchy() -> Bool {
        var nextResponder = self.nextOrParent()
        while nextResponder != nil {
            if nextResponder as? UIWindow != nil {
                return true
            }
            nextResponder = nextResponder?.nextOrParent()
        }
        
        return false
    }
}

extension UIResponder {
    @MainActor
    func nextOrParent() -> UIResponder? {
        (self as? UIViewController)?.parent?.next ?? self.next
    }
}

struct AnchorPointAssociatedKeys {
    nonisolated(unsafe) static var leakAnchorKey: UInt8 = 0
    nonisolated(unsafe) static var driftReporterKey: UInt8 = 0
}
