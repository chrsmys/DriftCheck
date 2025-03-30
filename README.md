![Image](https://driftcheck-assets.s3.us-east-1.amazonaws.com/HeaderImage.png)

# 🚤 DriftCheck - Catch memory leaks instantly

**DriftCheck** is a lightweight library that helps you detect retain cycles and forgotten references by tethering your objects to the well-defined lifecycle of UIKit/SwiftUI views. Get notified instantly when memory leaks:

```
⚓️ SkiffViewController<0x130504280> still exists past it's retention plan.
Some tethered objects still remain:
🛟 UIView<0x130509c70>
```

---

## 🌊 The Problem

It’s surprisingly easy to leak memory in your app without realizing it. If memory leaks go unaddressed, they can increase your app’s memory footprint — which leads to your app being terminated faster in the background. In severe cases, your app might even be terminated while foregrounded.

But memory usage isn’t the only concern. Leaked objects can cause unexpected and hidden bugs that are much harder to track down.

Let's look at an example:

Imagine you’re building an app to track commercial fishing boats. Fishermen select their current boat, and the app refreshes that boat’s location every few seconds based on the phone’s GPS.

```swift
import UIKit

class LeakyBoatViewController: UIViewController {
    private var timer: Timer?

    let boatID: String

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
           self. refreshBoatStatus()
        }
    }

    private func refreshBoatStatus() {
        print("🔄 Refreshing boat status for boat id \(boatID)...")
    }

    deinit {
        timer?.invalidate()
    }
}
```

In this example, `LeakyBoatViewController` uses a timer to update the boat’s status every 5 seconds. But there’s a problem: the timer’s closure strongly captures self, which means the view controller never deallocates.

Even after the fisherman leaves the boat and dismisses `LeakyBoatViewController`, the app will continue updating the boat’s status based on the fisherman’s phone location. Land ho!

---

## 🛟 The Solution - DriftCheck

UIKit/SwiftUI lifecycles are predictable and well understood. When a view or view controller is removed from the heirarchy we typically expect it to be deallocated. (This isn’t always the case — but don’t worry, **DriftCheck** handles those edge cases too. Keep reading.)

**DriftCheck** leverages these known lifecycles by allowing you to `tether` any reference type to a UIView/UIViewController/SwiftUI View. These views and view controllers are known as **Anchors**.

When an **Anchor** is removed from the view hierarchy, **DriftCheck** automatically verifies that both the **Anchor** itself and any tethered objects have been deallocated.

If any memory has “drifted away” — **DriftCheck** will report it.

<img width="1395" alt="Image" src="https://driftcheck-assets.s3.us-east-1.amazonaws.com/DriftExample.png" />

---

## ⚓️ Get Started

### Swift Package Manager (SPM)

1. From the File menu, select Add Package Dependencies...
2. Enter "https://github.com/chrsmys/driftcheck-private" into the package repository URL text field.
3. Add `DriftCheck` to your app target.

### Usage

By default any ViewController provided by your app is automatically tracked. Simply start the drift reporter in your app delegate:

```swift
import DriftCheck

func application(_ application: UIApplication,
                             didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
 ) -> Bool {

    DriftReporter.shared.start()

    return true
}
```

If you want to monitor an object that is not an **Anchor** you can simply `tether` it to an **Anchor** that matches it's expected lifecycle:

**UIKit**:

```swift
class SkiffViewController: UIViewController {

   let viewModel = SkiffViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Tether the view model to this ViewController’s lifecycle
        tether(viewModel)
    }
}
```

**SwiftUI**:

```swift
struct SkiffView: View {
    @State var viewModel: SkiffViewModel = .init()
    var body: some View {
        VStack {
            Text("I can't believe it's not boater")
        }
        // State objects can easily be leaked if you are not careful.
        // This tethers the state object to the lifecycle of the SwiftUI view.
        .tether(viewModel)
    }
}
```

When `SkiffViewController` or `SkiffView` is removed from the view hierarchy **DriftCheck** will automatically verify that the instance of SkiffViewModel is deallocated. In the UIKit example it will also verify that `SkiffViewController` is deallocated when dismissed.

## 🐟 Customization

### Customize Reporting Behavior

By default **DriftCheck** triggers a runtime warning and prints to the console whenever there is a leak. If you want to customize this behavior you can set `DriftReporter`'s `exceptionBehaviors`:

```swift
// Behaviors are performed in order
DriftReporter.shared.exceptionBehaviors = [
        // Logs to the console
        .log,
        // Triggers a runtime warning.
        .runtimeWarning
        // Triggers an assertionFailure
        .assert,
        // Triggers a breakpoint
        .breakpoint,
        // Allows for custom behavior like in app toasts
        .custom { result in
            // Perform custom logic here based on the result
        }
    ]

```

### Customizing When Exceptions are Triggered

Every **Anchor** has a `retentionMode`. The `retentionMode` determines when **DriftCheck** will verify that both the `Anchor` and its tethers were properly deallocated. The 3 modes you can choose from are:

| RetentionMode             | Description                                                                                                                                                                                                                           | Arguments                                                                                                                                                                     |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.onRemovalFromHierarchy` | DriftReporter will run a drift check on the Anchor and it's tethers when the Anchor is removed from the view Hierarchy. <br/><br/> **Default value for**: <ul><li>Any UIViewController not provided by the standard library</li></ul> | `waitFrames`: The number of frames that should be waited before `DriftReporter` runs a drift check. This is useful when you have short operations that occur after dismissal. |
| `.onDealloc`              | DriftReporter will run a drift check on the **Anchor's** tethers when the **Anchor** is deallocated. <br/><br/> **Default value for**: <ul><li>Any UIView with a tether attached</li></ul>                                            | N/A                                                                                                                                                                           |
| `.optOut`                 | DriftReporter will not run a drift check <br/><br/> **Default value for**: <ul><li>Any UIView without a tether attached</li><li>Any UIViewController provided through the standard library.</li></ul>                                 | N/A                                                                                                                                                                           |

There are two ways to customize this behavior. At an individual **Anchor** level you can set the `retentionMode`:

```swift
viewController.retentionMode = .optOut
```

You can also set the `DriftReporter`'s `retentionPlan` which will determine the behavior for all View/ViewController's that do not have a `retentionMode` set.

```swift
DriftReporter.shared.retentionPlan = { anchor in
    if let anchorView = anchor as? UIView {
        return .optOut
    }

    return .onRemovalFromHierarchy()
}
```

## ⛵ Example App

The provided [Example app](DriftCheckExample/DriftCheckExample.xcodeproj) includes four common memory leak scenarios that developers often run into.

DriftCheck is already configured to detect each of these leaks. As a challenge, see if you can:

-   Spot the leaks using **DriftCheck**’s output
-   Fix the issues in each example
-   Verify that **DriftCheck** no longer triggers an exception.

If you get stuck, the Solutions folder walks through how to identify and fix each leak, complete with code and visual guides.

## 🏴‍☠️ What To Do When a Leak Occurs

The first step to fixing a memory leak is knowing there _is_ a memory leak. **DriftCheck** will notify you as soon as it detects one. Often, catching a leak early makes it easy to trace it back to a recent code change.

For those cases where the cause isn’t immediately obvious, let’s walk through a leak investigation using `Example1` from the included project.

### 🧪 Step 1: Reproduce the Leak

Build and run the [Example project](DriftCheckExample/DriftCheckExample.xcodeproj). Navigate to Example1, then exit the screen. You should see a report like this:

```
⚓️ Example1<0x130504280> still exists past it's retention plan.
Some tethered objects still remain:
🛟 UIView<0x130509c70>
```

This report is telling us two things:

1. The **Anchor** (Example1) still exists after it was expected to be deallocated.
2. A tethered view (UIView) is also still in memory.

<img src="https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExYXV1YWJyM25sb3diOWZrZWw0N2l0a3pyeGw2YWt0enpjMjE4eXM2MiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/1yY2RugygPSr4onbsy/giphy.gif" width="fill" />

### 🧰 Step 2: Use the Memory Graph

Xcode’s Debug Memory Graph tool is invaluable for debugging leaks like these.

1. Run the app in Debug mode
2. Open the Memory Graph from the Debug Navigator
3. Copy the memory address from the DriftCheck report (e.g. 0x130504280)
4. Paste it into the Memory Graph’s search field and select the matching object

See [Apple's guide on using the Memory Graph tool](https://developer.apple.com/documentation/xcode/gathering-information-about-memory-use#Inspect-the-debug-memory-graph) for more information.

| Step 2                                                                                                | Step 3-4                                                                                              |
| ----------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| <img width="fill" alt="Image" src="https://driftcheck-assets.s3.us-east-1.amazonaws.com/Step2.png" /> | <img width="fill" alt="Image" src="https://driftcheck-assets.s3.us-east-1.amazonaws.com/Step3.png" /> |

You should now see a zoomed in graph like in the picture above. Everything to the left of the node shows what retains it. Everything to the right shows what it retains.

### 🌀 Step 3: Identify the Retain Cycle

A retain cycle is a circular reference — a case where an object holds onto something that ends up holding onto it.

If you click the UIHostingView on the right side you can actually see that a UIHostingView on the left side is highlighted, indicating that it is the same instance that owns the instance of Example1 and is owned by Example1. We have found our memory leak.

<img width="fill" alt="Image" src="https://driftcheck-assets.s3.us-east-1.amazonaws.com/Identify.png" />

### 🧵 Step 4: Find the Leak in code

Let’s look at the code for Example1. Specifically we know that the leak is due to the HostingView holding onto Example1. Let's focus on that:

```swift
import SwiftUI

class Example1: UIViewController {

    lazy var hostingView: UIView = UIHostingConfiguration {
        VStack {
            Button {
                self.navigationController?.popViewController(animated: true)
                // ↑ Strong capture of self inside the action block
            } label: {
                Text("Go Back")
            }
        }
    }
        .margins(.all, 0)
        .makeContentView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground

        self.hostingView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(hostingView)

        self.hostingView.pin(to: self.view)
    }
}
```

The issue: The Button action within the hosting view strongly captures self, preventing Example1 from being deallocated.

### ✅ The Fix

Use `[weak self]` to avoid the retain cycle:

```swift
Button { [weak self] in
   self?.navigationController?.popViewController(animated: true)
 } label: {
   Text("Go Back")
}
```

Now when you run the app, open Example1, and dismiss it, **DriftCheck** will no longer report a leak. 🎊

## 🤝 Contributing

Contributions are welcome — especially if you’ve encountered tricky retain cycles in your own apps!

If you have a leak that wasn’t caught in the current examples, or one that took you a while to debug, consider turning it into a new test case.

### 🎣 Ways to Contribute

-   Add new example view controllers that demonstrate common or tricky leaks
-   Write unit tests that simulate memory lifecycle issues
-   Improve the Solutions folder with step-by-step walkthroughs
-   Report issues or suggest features

### Where to Look

-   Add new examples to the DriftCheckExample target in DriftCheckExample/Examples/
-   Include a matching fix and walkthrough (optional) in the Solutions/ folder
-   Add test coverage in DriftCheckTests/

If you’re unsure where to start, feel free to open an issue — happy to collaborate!
