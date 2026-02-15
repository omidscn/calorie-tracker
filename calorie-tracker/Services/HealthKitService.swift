import Foundation
import HealthKit

struct HealthProfile: Sendable {
    var biologicalSex: BiologicalSex?
    var age: Int?
    var heightCm: Double?
    var weightKg: Double?
}

final class HealthKitService {
    private let healthStore = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorizationAndRead() async throws -> HealthProfile {
        let typesToRead: Set<HKObjectType> = [
            HKCharacteristicType(.biologicalSex),
            HKCharacteristicType(.dateOfBirth),
            HKQuantityType(.height),
            HKQuantityType(.bodyMass),
        ]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        return try await readProfile()
    }

    private func readProfile() async throws -> HealthProfile {
        var profile = HealthProfile()

        if let bioSex = try? healthStore.biologicalSex().biologicalSex {
            switch bioSex {
            case .male: profile.biologicalSex = .male
            case .female: profile.biologicalSex = .female
            default: break
            }
        }

        if let dobComponents = try? healthStore.dateOfBirthComponents(),
           let birthDate = Calendar.current.date(from: dobComponents) {
            let years = Calendar.current.dateComponents([.year], from: birthDate, to: .now).year
            if let years, years >= 15, years <= 100 {
                profile.age = years
            }
        }

        if let sample = try await mostRecentSample(for: .height) {
            profile.heightCm = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
        }

        if let sample = try await mostRecentSample(for: .bodyMass) {
            profile.weightKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
        }

        return profile
    }

    private func mostRecentSample(for identifier: HKQuantityTypeIdentifier) async throws -> HKQuantitySample? {
        let type = HKQuantityType(identifier)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )
        let results = try await descriptor.result(for: healthStore)
        return results.first
    }
}
