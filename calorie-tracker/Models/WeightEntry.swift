import Foundation
import SwiftData

@Model
final class WeightEntry {
    var weight: Double = 0.0
    var timestamp: Date = Date.now

    init(weight: Double, timestamp: Date = .now) {
        self.weight = weight
        self.timestamp = timestamp
    }
}
