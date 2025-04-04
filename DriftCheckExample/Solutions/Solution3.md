## Step 0

This guide assumes you have a baseline understanding of retain cycles and Xcode's Memory Graph Debugger. If you are unfamiliar then please check out [Solution 1](./Solution1.md) & [Solution 2](./Solution2.md) first.

## 🧪 Step 1: Reproduce the Leak

![Gif showing the Example app being run with leak on dismissal](https://driftcheck-assets.s3.us-east-1.amazonaws.com/Solution3/ReproLeak.gif)

Build and run the [Example project](DriftCheckExample/DriftCheckExample.xcodeproj). Navigate to the third example ("Boat name ideas") then close it. You should see a report like this:

```
⚓️ BoatNamesViewController<0x1199047c0> still exists past its retention plan.
Some tethered objects still remain:
🛟 UIView<0x119d0a170>
```

This report is telling us that 2 things are being retained:

1. The **Anchor** (BoatNamesViewController)
2. BoatNamesViewController's UIView

## 🧰 Step 2: Use the Memory Graph

Now that we know that the anchor (BoatNamesViewController) has being retained let's check that out in the memory Graph Debugger first. Copy it's memory address (ex: 0x1199047c0) from the DriftCheckout output and past it into the memory graph debug.

![Gif showing opening the memory graph and pasting the memory address into the navigator](https://driftcheck-assets.s3.us-east-1.amazonaws.com/Solution3/OpenMemoryGraph.gif)

See [Solution1.md](./Solution1.md) or [Apple's guide on using the Memory Graph tool](https://developer.apple.com/documentation/xcode/gathering-information-about-memory-use#Inspect-the-debug-memory-graph) for more information on how to do this.

## 🌀 Step 3: Identify the Retain Cycle

Let's first see if any of the direct items that BoatNamesViewController owns reveals a retain cycle:

![Gif showing clicking through memory graph debugger](https://driftcheck-assets.s3.us-east-1.amazonaws.com/Solution3/SelectOwnership.gif)

Remember in [Solution 1](./Solution1.md) & [Solution 2](./Solution2.md) when we clicked through all of the nodes on the right side it revealed that one of the nodes also existed on the left side of the anchor. That didn't happen this time which means this retain cycle might be trickier. If we look at the left side of the anchor there also doesn't appear to be anything obvious:
![Left side of anchor](https://driftcheck-assets.s3.us-east-1.amazonaws.com/Solution3/LeftSide.png)

This _is_ a tricky one. The memory graph debugger hides some references in certain circumstances. You can reveal these references by hitting the more options menu on any node in the graph. The more button on the left side will reveal options for objects referencing the node and the more button on the right will reveal options for the objects the node is referencing. Let's see what is hidden on the left:

![Gif revealing hidden reference](https://driftcheck-assets.s3.us-east-1.amazonaws.com/Solution3/Culprit.gif)

The `[capture]` reference looks pretty suspicious. Let's follow it and see where it goes. In the above gif you can see that after continuing to dig a bit deeper it is reveled that the same instance of BoatNamesViewController is at the end of the node list. The node directly before the BoatNamesViewController is `UITableViewDiffableDataSource`.

## 🧵 Step 4: Find the Leak in code

Now that we know `UITableViewDiffableDataSource` is holding onto the instance of `BoatNamesViewController` we can zoom in on that portion of the code.

```swift
import UIKit

class BoatNamesViewController: UIViewController {
    ...

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: configureCell)
    }

    private func configureCell(tableView: UITableView, indexPath: IndexPath, boat: Boat) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = boat.name
        return cell
    }

   ...
}
```

This all looks pretty innocent at first. In fact there is seemingly no references to self to capture. In order to find the fix you have to know that passing a function as a closure implicitly captures self. `cellProvider` expects to be passed a closure and we are passing it the `configureCell` function. This is equivalent to:

```swift
 private func configureDataSource() {
      dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
            return self.configureCell(tableView: tableView, indexPath: indexPath, boat: item)
        })
 }
```

Hopefully this makes the retain cycle a lot more clear.

## ✅ The Fix

You actually have two options for fixes:

### Weak Self

Instead of passing the function directly you can provide a closure, weakly capture self, and then call configureCell if self is not nil.

```swift
 private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
            guard let self else { return nil }
            return self.configureCell(tableView: tableView, indexPath: indexPath, boat: item)
        })
}

private func configureCell(tableView: UITableView, indexPath: IndexPath, boat: Boat) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = boat.name
        return cell
}
```

**Drawbacks**:

-   More verbose
-   Requires you to handle if self is nil

### Static configure cell

Another option is to make configureCell a static function. Passing a static function will not implicitly capture any references to BoatNamesViewController.

```swift
 private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: BoatNamesViewController.configureCell)
}

private static func configureCell(tableView: UITableView, indexPath: IndexPath, boat: Boat) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = boat.name
        return cell
}
```

**Drawbacks**:

-   You can't reference any instance level properties within the static function. This is not an issue for this use case, but could be for others.

## Conclusion

Choose one of the solutions above, rerun the app, and you should see BoatNamesViewController is no longer retained 🎊
