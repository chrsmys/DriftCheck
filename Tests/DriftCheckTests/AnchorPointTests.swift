import XCTest
@testable import DriftCheck
import UIKit

final class AnchorPointTests: XCTestCase {
    
    @MainActor
    func testRetentionPlan() throws {
        let driftReporter = DriftReporter()
        driftReporter.exceptionBehvaiors = []
        let vc = UIViewController()
        vc.driftReporter = driftReporter
        XCTAssertEqual(vc.retentionMode, .optOut)
        
        let vc2 = TestVC()
        vc2.driftReporter = driftReporter
        XCTAssertEqual(vc2.retentionMode, .onRemovalFromHierarchy(waitFrames: 2))
        
        let view = UIView()
        view.driftReporter = driftReporter
        XCTAssertEqual(view.retentionMode, .optOut)
        
        let object = NSObject()

        view.tether(object)
        XCTAssertEqual(view.retentionMode, .onDealloc)

        let view2 = TestView()
        view.driftReporter = driftReporter
        XCTAssertEqual(view2.retentionMode, .optOut)
        
        view2.retentionMode = .onRemovalFromHierarchy(waitFrames: 2)
        XCTAssertEqual(view2.retentionMode, .onRemovalFromHierarchy(waitFrames: 2))
    }
    
    @MainActor
    func testTether() throws {
        let driftReporter = DriftReporter()
        let object = NSObject()
        let vc = TestVC()
        vc.driftReporter = driftReporter
        vc.tether(object)
        
        let tethers = driftReporter.tetherRegistry.tethers(vc)
        let anchors = driftReporter.tetherRegistry.anchors(object)

        XCTAssertEqual(tethers.count, 1)
        XCTAssertEqual(anchors.count, 1)
        XCTAssertTrue(tethers.contains(.init(item: object)))
        XCTAssertTrue(anchors.contains(vc.anchorId))
    }
    
    @MainActor
    func testMultipleTethers() throws {
        let driftReporter = DriftReporter()
        let object = NSObject()
        let object2 = NSObject()
        let vc = TestVC()
        vc.driftReporter = driftReporter
        vc.tether(object)
        vc.tether(object2)

        // Ensure adding a tether multiple times does nothing
        vc.tether(object)
        vc.tether(object2)

        
        let tethers = driftReporter.tetherRegistry.tethers(vc)
        let anchors = driftReporter.tetherRegistry.anchors(object)

        XCTAssertEqual(tethers.count, 2)
        XCTAssertEqual(anchors.count, 1)
        XCTAssertTrue(tethers.contains(.init(item: object)))
        XCTAssertTrue(tethers.contains(.init(item: object2)))
        XCTAssertEqual(anchors.first, vc.anchorId)
    }
    
    @MainActor
    func testIsInHeirarchyNavigationController() throws {
        let firstVC = TestVC()
        let secondVC = TestVC()
        let navigationController = UINavigationController(rootViewController: firstVC)
        let window = UIWindow()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        XCTAssertTrue(firstVC.isInHeirarchy())
        XCTAssertTrue(navigationController.isInHeirarchy())
        XCTAssertFalse(secondVC.isInHeirarchy())
        
        // When a new VC is pushed on the first VC technicaly gets
        // removed from the view heirarchy and responder chain
        // for the purposes of this library we still consider it
        // displayed and in the heirarchy.
        navigationController.pushViewController(secondVC, animated: false)
        XCTAssertTrue(firstVC.isInHeirarchy())
        XCTAssertTrue(secondVC.isInHeirarchy())
        
        navigationController.popViewController(animated: false)
        XCTAssertTrue(firstVC.isInHeirarchy())
        XCTAssertFalse(secondVC.isInHeirarchy())
        
        navigationController.setViewControllers([secondVC], animated: false)
        XCTAssertFalse(firstVC.isInHeirarchy())
        XCTAssertTrue(secondVC.isInHeirarchy())
    }
    
    @MainActor
    func testIsAppleType() {
        let viewController = UIViewController()
        XCTAssertTrue(viewController.isAppleType)
        
        let view = UIView()
        XCTAssertTrue(view.isAppleType)
        
        let testVC = TestVC()
        XCTAssertFalse(testVC.isAppleType)
        
        let testView = TestView()
        XCTAssertFalse(testView.isAppleType)
    }
}
