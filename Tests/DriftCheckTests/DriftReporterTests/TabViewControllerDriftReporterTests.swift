//
//  TabViewControllerDriftReporterTests.swift
//  DriftCheck
//
//  Created by Chris Mays on 3/26/25.
//

import XCTest
@testable import DriftCheck
import UIKit

final class TabViewControllerDriftReporterTests: XCTestCase {
    @MainActor
    func testNonCurrentTabIsNotified() async throws {
        let driftReporter = DriftReporter()
        driftReporter.start()

        let expectation = expectation(description: "Ensure drift report")
        
        let object = NSObject()
        let vc = UIViewController()
        
        driftReporter.exceptionBehvaiors = [ .custom { [weak vc, weak object] report in
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
        
        let task = Task { @MainActor in
            let vc2 = UIViewController()
            vc2.driftReporter = driftReporter
            let tabViewController = UITabBarController()
            tabViewController.setViewControllers([vc, vc2], animated: false)
            let window = UIWindow()
            window.rootViewController = tabViewController
            window.makeKeyAndVisible()
            tabViewController.selectedIndex = 1
            await FrameWaiter.wait(frames: 3)
            window.rootViewController = UIViewController()
            await FrameWaiter.wait(frames: 3)
        }
        
        _ = await task.value
        
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    @MainActor
    func testNonCurrentTabIsNotifiedIfAnchorIsNil() async throws {
        let driftReporter = DriftReporter()
        driftReporter.start()

        let expectation = expectation(description: "Ensure drift report")
        
        let object = NSObject()
        
        driftReporter.exceptionBehvaiors = [ .custom { [weak object] report in
            guard let object else {
                assertionFailure("VC and Tether should not be nil")
                return
            }
            XCTAssertFalse(report.anchorItem.retained)
            XCTAssertEqual(report.tetheredItems.count, 1)
            XCTAssertNotNil(report.tetheredItems.first(where: {
                $0.id == hexAddress(object)
            }))
            expectation.fulfill()
        }]
        
        let task = Task { @MainActor in
            let vc = UIViewController()
            vc.driftReporter = driftReporter
            vc.tether(object)
            let vc2 = UIViewController()
            vc2.driftReporter = driftReporter
            let tabViewController = UITabBarController()
            tabViewController.setViewControllers([vc, vc2], animated: false)
            let window = UIWindow()
            window.rootViewController = tabViewController
            window.makeKeyAndVisible()
            tabViewController.selectedIndex = 1
            await FrameWaiter.wait(frames: 3)
        }
        
        _ = await task.value
        
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    @MainActor
    func testCurrentTabIsNotified() async throws {
        let driftReporter = DriftReporter()
        driftReporter.start()

        let expectation = expectation(description: "Ensure drift report")
        
        let object = NSObject()
        let vc = UIViewController()
        
        driftReporter.exceptionBehvaiors = [ .custom { [weak vc, weak object] report in
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
        
        let task = Task { @MainActor in
            let vc2 = UIViewController()
            vc2.driftReporter = driftReporter
            let tabViewController = UITabBarController()
            tabViewController.setViewControllers([vc, vc2], animated: false)
            let window = UIWindow()
            window.rootViewController = tabViewController
            window.makeKeyAndVisible()
            await FrameWaiter.wait(frames: 3)
        }
        
        _ = await task.value
        
        await fulfillment(of: [expectation], timeout: 0.5)
    }
}
