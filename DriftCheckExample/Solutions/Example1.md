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

| Step 2                                                                                                                 | Step 3-4                                                                                                               |
| ---------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| <img width="fill" alt="Image" src="https://github.com/user-attachments/assets/933822b2-8b17-4803-b193-b06a7a640a9a" /> | <img width="fill" alt="Image" src="https://github.com/user-attachments/assets/c9c54075-5fd5-4a0f-9d5f-bc2eaab65c18" /> |

You should now see a zoomed in graph like in the picture above. Everything to the left of the node shows what retains it. Everything to the right shows what it retains.

### 🌀 Step 3: Identify the Retain Cycle

A retain cycle is a circular reference — a case where an object holds onto something that ends up holding onto it.

If you click the UIHostingView on the right side you can actually see that a UIHostingView on the left side is highlighted, indicating that it is the same instance that owns the instance of Example1 and is owned by Example1. We have found our memory leak.

<img width="fill" alt="Image" src="https://github.com/user-attachments/assets/50814d27-6155-4ea6-a7d8-d918ea8fdf6a" />

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
