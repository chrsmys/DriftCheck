# Xcode Memory Graph Debugger Gotchas

Below is a brain dump of gotchas with the memory graph debugger

## Hidden Nodes & Retain Cycles

Xcode hides certain nodes in the graph to simplify things and make it easier to read. However, these hidden nodes can also obscure retain cycles. Everything below is based on observation and speculation, because as far as I can tell, this behavior isn’t documented anywhere. If you find documentation for this please open an issue or pull request.

### Hidden References To A Node

Xcode’s Memory Graph only shows the **shortest path** from each object back to a root (like the app delegate or window). If an object is reachable via multiple paths, the graph hides any longer paths that lead to the same root, displaying only the shortest one.

Unfortunately, this can hide retain cycles. Retain cycles almost always involve these secondary, longer paths—because, by definition, they form a loop in the graph.

![Example of hidden reference to node](https://driftcheck-assets.s3.us-east-1.amazonaws.com/Solution3/ExampleHiddenReference.gif)

### Hidden References From A Node

When a node has more than 6 outgoing references, the Memory Graph Debugger will hide the rest. This becomes especially troublesome as your app gets more complex and objects start referencing many things—views, closures, timers, etc.

![Example of hidden reference from a node](https://driftcheck-assets.s3.us-east-1.amazonaws.com/Solution3/ExampleHiddenReference2.gif)
