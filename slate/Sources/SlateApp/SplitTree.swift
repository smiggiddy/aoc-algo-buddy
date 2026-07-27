import Foundation
import SlateTerminal

/// A binary split tree, the same model Ghostty uses: every split divides one
/// pane into two, so any layout is reachable and every pane has a well-defined
/// neighbour in each direction.
public indirect enum SplitNode: Identifiable {
    case leaf(TerminalSurface)
    case split(Split)

    public struct Split: Identifiable {
        public let id = UUID()
        public var axis: Axis
        public var first: SplitNode
        public var second: SplitNode
        /// First pane's share of the axis, 0...1.
        public var ratio: Double = 0.5
    }

    public enum Axis {
        case horizontal // side by side
        case vertical   // stacked
    }

    public var id: UUID {
        switch self {
        case .leaf(let surface): surface.id
        case .split(let split): split.id
        }
    }

    /// Every surface in the tree, left to right, top to bottom.
    public var surfaces: [TerminalSurface] {
        switch self {
        case .leaf(let surface): [surface]
        case .split(let split): split.first.surfaces + split.second.surfaces
        }
    }

    public func contains(_ surfaceID: UUID) -> Bool {
        surfaces.contains { $0.id == surfaceID }
    }

    /// Replaces the leaf holding `surfaceID` with a new split containing it and
    /// `newSurface`. Returns false if the surface isn't in this tree.
    public mutating func split(
        _ surfaceID: UUID,
        with newSurface: TerminalSurface,
        direction: SplitDirection
    ) -> Bool {
        switch self {
        case .leaf(let surface):
            guard surface.id == surfaceID else { return false }
            let axis: Axis = (direction == .left || direction == .right) ? .horizontal : .vertical
            // "Split right" means the new pane goes second; "split left" means
            // it goes first. Same for down/up.
            let newIsSecond = (direction == .right || direction == .down)
            self = .split(Split(
                axis: axis,
                first: newIsSecond ? .leaf(surface) : .leaf(newSurface),
                second: newIsSecond ? .leaf(newSurface) : .leaf(surface)
            ))
            return true

        case .split(var split):
            if split.first.split(surfaceID, with: newSurface, direction: direction) {
                self = .split(split)
                return true
            }
            if split.second.split(surfaceID, with: newSurface, direction: direction) {
                self = .split(split)
                return true
            }
            return false
        }
    }

    /// Removes a surface, collapsing its parent split. Returns nil when the
    /// tree becomes empty, which the caller treats as "close the tab".
    public func removing(_ surfaceID: UUID) -> SplitNode? {
        switch self {
        case .leaf(let surface):
            return surface.id == surfaceID ? nil : self
        case .split(var split):
            let first = split.first.removing(surfaceID)
            let second = split.second.removing(surfaceID)
            switch (first, second) {
            case (nil, nil): return nil
            case (let remaining?, nil), (nil, let remaining?): return remaining
            case (let first?, let second?):
                split.first = first
                split.second = second
                return .split(split)
            }
        }
    }

    public mutating func setRatio(_ ratio: Double, forSplit splitID: UUID) {
        guard case .split(var split) = self else { return }
        if split.id == splitID {
            split.ratio = min(max(ratio, 0.1), 0.9)
        } else {
            split.first.setRatio(ratio, forSplit: splitID)
            split.second.setRatio(ratio, forSplit: splitID)
        }
        self = .split(split)
    }

    /// The neighbour of `surfaceID` in `direction`.
    ///
    /// Geometric rather than tree-order: walk up until we find an ancestor
    /// split on the matching axis where we came from the near side, then
    /// descend the far side. This is what makes ⌘⌥→ land where you expect
    /// instead of wherever the tree happens to put it.
    public func neighbor(of surfaceID: UUID, direction: SplitDirection) -> TerminalSurface? {
        var path: [(Split, Bool)] = [] // (split, cameFromFirst)
        guard buildPath(to: surfaceID, into: &path) else { return nil }

        let wantedAxis: Axis = (direction == .left || direction == .right) ? .horizontal : .vertical
        let wantForward = (direction == .right || direction == .down)

        for (split, cameFromFirst) in path.reversed() {
            guard split.axis == wantedAxis else { continue }
            if wantForward && cameFromFirst {
                return split.second.surfaces.first
            }
            if !wantForward && !cameFromFirst {
                return split.first.surfaces.last
            }
        }
        return nil
    }

    private func buildPath(to surfaceID: UUID, into path: inout [(Split, Bool)]) -> Bool {
        switch self {
        case .leaf(let surface):
            return surface.id == surfaceID
        case .split(let split):
            path.append((split, true))
            if split.first.buildPath(to: surfaceID, into: &path) { return true }
            path.removeLast()

            path.append((split, false))
            if split.second.buildPath(to: surfaceID, into: &path) { return true }
            path.removeLast()

            return false
        }
    }
}

public enum SplitDirection {
    case left, right, up, down
}
