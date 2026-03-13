import ApplicationServices

/// Visitor-pattern tree traversal of the AX hierarchy with cycle detection.
/// Inspired by AXray's recursive walker — uses a seen-set of element hashes
/// to avoid infinite loops in apps with circular AX references.
final class AXTreeWalker {
    struct Options {
        var maxDepth: Int = 30
        var maxElements: Int = 5000
    }

    private let options: Options
    private var visited = Set<UInt64>()
    private var elementCount = 0

    init(options: Options = Options()) {
        self.options = options
    }

    /// Walk the AX tree rooted at the given app element, calling the visitor for each node.
    func walk(root: AXElement, visitor: (AXElement, Int) -> Bool) {
        visited.removeAll()
        elementCount = 0
        walkRecursive(element: root, depth: 0, visitor: visitor)
    }

    /// Collect all leaf/actionable elements from the tree.
    func collectElements(root: AXElement) -> [AXElement] {
        var elements: [AXElement] = []
        walk(root: root) { element, _ in
            elements.append(element)
            return true // continue
        }
        return elements
    }

    private func walkRecursive(element: AXElement, depth: Int, visitor: (AXElement, Int) -> Bool) {
        guard depth < options.maxDepth, elementCount < options.maxElements else { return }

        // Cycle detection using the raw pointer value as a hash
        let hash = UInt64(UInt(bitPattern: Unmanaged.passUnretained(element.underlying).toOpaque()))
        guard !visited.contains(hash) else { return }
        visited.insert(hash)

        elementCount += 1

        // Visit this element; if visitor returns false, stop descending
        guard visitor(element, depth) else { return }

        // Recurse into children
        for child in element.children {
            guard elementCount < options.maxElements else { break }
            walkRecursive(element: child, depth: depth + 1, visitor: visitor)
        }
    }
}
