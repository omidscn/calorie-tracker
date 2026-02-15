import Foundation
import SwiftData

@Model
final class WeightEntry {
    var weight: Double
    var timestamp: Date

    init(weight: Double, timestamp: Date = .now) {
        self.weight = weight
        self.timestamp = timestamp
    }
}
