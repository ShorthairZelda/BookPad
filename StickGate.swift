import Foundation

// A gesture starts only after centering. Holding or jittering cannot repeat it.
struct StickGate {
    private var armed = false

    mutating func update(x: Float, y: Float) -> Int? {
        guard let direction = updateDirection(x: x, y: y) else { return nil }
        return direction == .left ? -1 : direction == .right ? 1 : nil
    }

    enum Direction { case left, right, up, down }

    mutating func updateDirection(x: Float, y: Float) -> Direction? {
        guard x.isFinite, y.isFinite else { armed = false; return nil }
        if abs(x) <= 0.25 && abs(y) <= 0.25 {
            armed = true
            return nil
        }
        guard armed, max(abs(x), abs(y)) >= 0.60 else { return nil }
        // A diagonal needs a clear dominant axis before it can fire.
        guard abs(abs(x) - abs(y)) >= 0.15 else { return nil }
        armed = false
        if abs(x) > abs(y) { return x < 0 ? .left : .right }
        return y > 0 ? .up : .down
    }
}
