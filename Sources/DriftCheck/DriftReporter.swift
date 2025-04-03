// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

/// Monitors the lifecycle of all anchors/tethers and fires exceptions when they exist
/// past their retentionMode.
@MainActor
public class DriftReporter {
    
    /// The shared singleton.
    public static let shared = DriftReporter()
    
    /// An ordered set of actions performed in order each time a drift check exception occurs.
    public var exceptionBehvaiors: [ExceptionBehavior] = [
        ExceptionBehavior.log,
        ExceptionBehavior.runtimeWarning
    ]
    
    var retentionModeOverrides: [String: RetentionMode] = [:]
    
    let tetherRegistry = TetherRegistry()

    var currentEvaluations = Set<String>()

    /**
     This block determines the default retentionMode for all anchors. If retentionMode is
     explicitly set on an anchor then this block will not be used. By default UIViews have the
     retentionMode of 'optOut' unless it has tethers, then it is 'onDealloc'. ViewControllers provided
     by the have a retentionMode of 'onRemovalFromHierarchy', and ViewControllers provided by
     a standard library are 'optOut'.
     */
    public lazy var retentionPlan: (_ anchor: AnchorPoint)-> RetentionMode = { [weak self] anchor in
        guard let self else { return .optOut }

        if let anchorView = anchor as? UIView {
            if tetherRegistry.hasTethers(anchorView) {
                return .onDealloc
            } else {
                return .optOut
            }
        }
        
        if anchor.isAppleType && !tetherRegistry.hasTethers(anchor) {
            return .optOut
        }
        
        return .onRemovalFromHierarchy()
    }
    
    /**
     Call this method to start reporting issues. This should be fired early in the app start for the best results.
     */
    public func start() {
        UIViewController.startRetainCycleDetector()
        UIView.startRetainCycleDetector()
    }
    
    func tether(_ item: AnyObject, to pin: AnchorPoint) {
        tetherRegistry.register(item, anchor: pin)
    }
    
    func untether(_ item: AnyObject, from pin: AnchorPoint) {
        tetherRegistry.unregister(item, anchor: pin)
    }
    
    /*
        Ensures that the provided anchor is null as well as all tethered objects.
        If either the anchor or any tether objects or not nil then an exception will be
        handled by the designated exceptionBehvaiors specified
     */
    func checkForDrift(_ anchor: AnchorPoint?, anchorId: String, anchorType: String) {
        var tetheredItems: [DriftCheckException.Item] = []
        while let weakObject = tetherRegistry.popFrom(anchorId: anchorId) {
            // If the item still exists and is not tethered to anything else
            // then that means it has drifted away.
            guard let tempRetainedItem = weakObject.item, !tetherRegistry.isAnchored(tempRetainedItem) else {
                continue
            }
            tetheredItems.append(
                .init(id: hexAddress(tempRetainedItem),
                      type:String(describing: type(of:tempRetainedItem)),
                      retained: true,
                      item: tempRetainedItem))
        }
        guard anchor != nil || !tetheredItems.isEmpty else { return }
        let result: DriftCheckException = .init(anchorItem: .init(id: anchorId, type: anchorType, retained: anchor != nil), tetheredItems: tetheredItems)
        exceptionBehvaiors.forEach {
            $0.handleResult(result: result)
        }
    }
}
