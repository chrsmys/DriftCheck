### Step 0

This guide assumes you have a baseline understanding of retain cycles and Xcode's Memory Graph Debugger. If you are unfamiliar then please check out [Solution 1](./Solution1.md) first. The solution to this problem is very similar to [Solution 1](./Solution1.md). If you feel that you understand Solution 1 then feel free to skip to [Solution3.md](./Solution3.md).

### 🧪 Step 1: Reproduce the Leak

![Gif showing the Example app being run with leak on dismissal](https://driftcheck-assets.s3.us-east-1.amazonaws.com/Solution2/ReproLeak.gif)

Build and run the [Example project](DriftCheckExample/DriftCheckExample.xcodeproj). Navigate to the second example, then exit the screen. You should see a report like this:

```
⚓️ GrogCounterViewController<0x1074043c0> still exists past its retention plan.
Some tethered objects still remain:
🛟 UIView<0x1071067c0>
🛟 UIHostingContentView<GrogCounterView, EmptyView><0x11c80000 >
```

This report is telling us that 3 things are being retained:

1. The **Anchor** (GrogCounterViewController)
2. GrogCounterViewController's UIView
3. UIHostingContentView

### 🧰 Step 2: Use the Memory Graph

Now that we know that the anchor (GrogCounterViewController) has being retained let's check that out in the memory Graph Debugger first. Copy its memory address (ex: 0x11cf04480) from the DriftCheckout output and past it into the memory graph debug.

![Gif showing opening the memory graph and pasting the memory address into the navigator](https://driftcheck-assets.s3.us-east-1.amazonaws.com/Solution2/OpenMemoryGraph.gif)

See [Solution1.md](./Solution1.md) or [Apple's guide on using the Memory Graph tool](https://developer.apple.com/documentation/xcode/gathering-information-about-memory-use#Inspect-the-debug-memory-graph) for more information on how to do this.

### 🌀 Step 3: Identify the Retain Cycle

Whenever I am first investigating a retain cycle I first just click through all of the items that the retained object holds onto. If there is a simple retain cycle then the issue typically jumps out.

![Gif showing clicking through memory graph debugger](https://driftcheck-assets.s3.us-east-1.amazonaws.com/Solution2/RetainCycleFound1.gif)

When you click on the UIHostingView on the right side of GrogCounterViewController you should see that a UIHostingView on the left side is highlighted as well. This indicates that they are the same instance. We have found our memory leak.

### 🧵 Step 4: Find the Leak in code

Let’s look at the code for GrogCounterViewController. Specifically we know that the leak is due to the HostingView holding onto GrogCounterViewController. Let's focus on that:

```swift
import SwiftUI

class GrogCounterViewController: UIViewController {
    lazy var hostingView = UIHostingConfiguration {
        GrogCounterView {
            self.dismiss(animated: true)
        }
    }
        .margins(.all, 0)
        .makeContentView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.title = "Grog Counter"
        self.hostingView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(hostingView)
        tether(hostingView)
        self.hostingView.pin(to: self.view)
    }
}
```

The issue: GrogCounterView holds onto a block that captures self, and self owns the hostingView which owns GrogCounterView 🤝.

### ✅ The Fix

Use `[weak self]` to avoid the retain cycle:

```swift
GrogCounterView { [weak self] in
   self.dismiss(animated: true)
}
```

Now when you run the app, open GrogCounterView, and dismiss it, **DriftCheck** will no longer report a leak. 🎊. Now that Solution 1 and Solution 2 have covered blocks capturing self, let's look at a different retain cycle that commonly occurs in [Solution 3](./Solution3.md).
