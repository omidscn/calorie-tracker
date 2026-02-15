import Foundation

final class CloudSyncedDefaults: NSObject {
    static let shared = CloudSyncedDefaults()

    private let defaults = UserDefaults.standard
    private let cloud = NSUbiquitousKeyValueStore.default

    private let syncedKeys: [String] = [
        "hasCompletedOnboarding",
        "dailyCalorieGoal",
        "userBiologicalSex",
        "userAge",
        "userHeightCm",
        "userWeightKg",
        "userActivityLevel",
        "userWeightGoal",
        "userTargetWeightKg",
        "aiEnabled"
    ]

    private var isSyncing = false

    private override init() {
        super.init()
    }

    func startSyncing() {
        // Pull latest from iCloud
        cloud.synchronize()

        // iCloud wins: pull cloud values into local (handles fresh installs)
        pullAllFromCloud()

        // Push any local-only values to iCloud (seeds first device)
        pushAllToCloud()

        // Observe iCloud changes from other devices
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud
        )

        // Observe local UserDefaults changes via KVO
        for key in syncedKeys {
            defaults.addObserver(self, forKeyPath: key, options: .new, context: nil)
        }
    }

    // MARK: - iCloud → Local

    @objc private func cloudDidChange(_ notification: Notification) {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        for key in syncedKeys {
            guard let cloudValue = cloud.object(forKey: key) else { continue }
            let localValue = defaults.object(forKey: key)

            if !valuesEqual(cloudValue, localValue) {
                defaults.set(cloudValue, forKey: key)
            }
        }
    }

    // MARK: - Local → iCloud

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let key = keyPath, syncedKeys.contains(key), !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let localValue = defaults.object(forKey: key)
        let cloudValue = cloud.object(forKey: key)

        if !valuesEqual(localValue, cloudValue) {
            if let value = localValue {
                cloud.set(value, forKey: key)
            } else {
                cloud.removeObject(forKey: key)
            }
        }
    }

    // MARK: - Helpers

    private func pullAllFromCloud() {
        for key in syncedKeys {
            if let cloudValue = cloud.object(forKey: key) {
                let localValue = defaults.object(forKey: key)
                if !valuesEqual(cloudValue, localValue) {
                    defaults.set(cloudValue, forKey: key)
                }
            }
        }
    }

    private func pushAllToCloud() {
        for key in syncedKeys {
            if let value = defaults.object(forKey: key) {
                let cloudValue = cloud.object(forKey: key)
                if !valuesEqual(value, cloudValue) {
                    cloud.set(value, forKey: key)
                }
            }
        }
    }

    private func valuesEqual(_ a: Any?, _ b: Any?) -> Bool {
        switch (a, b) {
        case (nil, nil):
            return true
        case (nil, _), (_, nil):
            return false
        case let (a as String, b as String):
            return a == b
        case let (a as Int, b as Int):
            return a == b
        case let (a as Double, b as Double):
            return a == b
        case let (a as Bool, b as Bool):
            return a == b
        case let (a as NSNumber, b as NSNumber):
            return a == b
        default:
            return false
        }
    }
}
