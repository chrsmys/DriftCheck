//
//  UINavigationController+DriftReporterTests.swift
//  DriftCheck
//
//  Created by Chris Mays on 3/26/25.
//

import XCTest
@testable import DriftCheck
import UIKit

final class NavigationControllerDriftReporterTests: XCTestCase {

    @MainActor
    func testTetherDrift() async throws {
        let driftReporter = DriftReporter()
        let object = NSObject()
        driftReporter.start()
        let expectation = expectation(description: "Ensure drift report")
        driftReporter.exceptionBehaviors = [.custom { report in
            XCTAssertFalse(report.anchorItem.retained)
            XCTAssertEqual(report.tetheredItems.count, 1)
            XCTAssertEqual(report.tetheredItems.first?.id, hexAddress(object))
            expectation.fulfill()
        }]
        
        autoreleasepool {
            let vc = TestVC()
            vc.driftReporter = driftReporter
            vc.tether(object)
            let navigationController = UINavigationController(rootViewController: vc)
            let window = UIWindow()
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }

        await fulfillment(of: [expectation], timeout: 0.5)
    }

    @MainActor
    func testAnchorPastRetentionPlan() async throws {
        let driftReporter = DriftReporter()
        driftReporter.start()

        let vc = TestVC()
        let object = NSObject()

        let expectation = expectation(description: "Ensure drift report")
        
        driftReporter.exceptionBehaviors = [.custom { [weak vc, weak object] report in
            guard let vc, let object else {
                assertionFailure("VC and Tether should not be nil")
                return
            }
            XCTAssertTrue(report.anchorItem.retained)
            XCTAssertEqual(report.tetheredItems.count, 2)
            XCTAssertNotNil(report.tetheredItems.first(where: {
                $0.id == hexAddress(vc.view)
            }))
            XCTAssertNotNil(report.tetheredItems.first(where: {
                $0.id == hexAddress(object)
            }))
            expectation.fulfill()
        }]
        
        vc.driftReporter = driftReporter
        vc.tether(object)

        autoreleasepool {
            let navigationController = UINavigationController(rootViewController: vc)
            let window = UIWindow()
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }

        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    @MainActor
    func testAppleTypesIngoredByDefault() async throws {
        let driftReporter = DriftReporter()
        driftReporter.start()
        
        let vc = UIViewController()
        vc.driftReporter = driftReporter
        XCTAssertEqual(vc.retentionMode, .optOut)
        driftReporter.exceptionBehaviors = [ .custom { _ in
            assertionFailure("Apple types should be ignored")
        }]
        
        let task = Task { @MainActor in
            let navigationController = UINavigationController(rootViewController: vc)
            let window = UIWindow()
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
            await FrameWaiter.wait(frames: 3)
        }
        
        _ = await task.value
        
        await FrameWaiter.wait(frames: 3)
    }
    
   
    @MainActor
    func testOverrideRetentionPlan() async throws {
        let driftReporter = DriftReporter()
        driftReporter.start()
        
        let vc = UIViewController()
        let object = NSObject()

        let expectation = expectation(description: "Ensure drift report")

        driftReporter.exceptionBehaviors = [ .custom { [weak vc, weak object] report in
            guard let vc, let object else {
                assertionFailure("VC and Tether should not be nil")
                return
            }
            XCTAssertTrue(report.anchorItem.retained)
            XCTAssertEqual(report.tetheredItems.count, 2)
            XCTAssertNotNil(report.tetheredItems.first(where: {
                $0.id == hexAddress(vc.view)
            }))
            XCTAssertNotNil(report.tetheredItems.first(where: {
                $0.id == hexAddress(object)
            }))
            expectation.fulfill()
        }]
        vc.driftReporter = driftReporter
        vc.tether(object)
        vc.retentionMode = .onRemovalFromHierarchy(waitFrames: 2)

        autoreleasepool {
            let navigationController = UINavigationController(rootViewController: vc)
            let window = UIWindow()
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    @MainActor
    func testAnchorNildRetentionPlan() async throws {
        let driftReporter = DriftReporter()
        driftReporter.start()
        
        let object = NSObject()

        let expectation = expectation(description: "Ensure drift report")

        driftReporter.exceptionBehaviors = [ .custom { [weak object] report in
            guard let object else {
                assertionFailure("Tether should not be nil")
                return
            }
            XCTAssertFalse(report.anchorItem.retained)
            XCTAssertEqual(report.tetheredItems.count, 1)
            XCTAssertNotNil(report.tetheredItems.first(where: {
                $0.id == hexAddress(object)
            }))
            expectation.fulfill()
        }]
        

        autoreleasepool {
            let vc = UIViewController()
            vc.driftReporter = driftReporter
            vc.tether(object)
            vc.retentionMode = .onRemovalFromHierarchy(waitFrames: 2)
            let navigationController = UINavigationController(rootViewController: vc)
            let window = UIWindow()
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    @MainActor
    func testNoException() async throws {
        let driftReporter = DriftReporter()
        driftReporter.start()
        driftReporter.exceptionBehaviors = [ .custom { _ in
            assertionFailure("No exception should be thrown")
        }]
        autoreleasepool {
            let vc = UIViewController()
            vc.driftReporter = driftReporter
            let object = NSObject()
            vc.tether(object)
            vc.retentionMode = .onDealloc
            let navigationController = UINavigationController(rootViewController: vc)
            let window = UIWindow()
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
        await FrameWaiter.wait(frames: 3)
    }
    
    @MainActor
    func testMultipleAnchors() async throws {
        let driftReporter = DriftReporter()
        driftReporter.start()
        driftReporter.exceptionBehaviors = [ .custom { _ in
            assertionFailure("No exception should be thrown")
        }]

        let object = NSObject()
        var viewController1: UIViewController = TestVC()
        viewController1.driftReporter = driftReporter
        viewController1.tether(object)
        
        var viewController2: UIViewController = TestVC()
        viewController2.driftReporter = driftReporter
        viewController2.tether(object)
        
        let navigationController = UINavigationController(rootViewController: viewController1)
        let window = UIWindow()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        await FrameWaiter.wait(frames: 3)

        viewController1 = UIViewController()
        
        navigationController.setViewControllers( [viewController2], animated: false)
        viewController2 = UIViewController()

        // Ensure draft exception not fired
        await FrameWaiter.wait(frames: 3)
        
        let expectation = expectation(description: "Ensure drift report")

        driftReporter.exceptionBehaviors = [ .custom { [weak object] report in
            guard let object else {
                assertionFailure("Tether should not be nil")
                return
            }
            XCTAssertFalse(report.anchorItem.retained)
            XCTAssertEqual(report.tetheredItems.count, 1)
            XCTAssertNotNil(report.tetheredItems.first(where: {
                $0.id == hexAddress(object)
            }))
            expectation.fulfill()
        }]
        
        navigationController.setViewControllers( [viewController1], animated: false)

        await fulfillment(of: [expectation], timeout: 1.5)
    }
}
