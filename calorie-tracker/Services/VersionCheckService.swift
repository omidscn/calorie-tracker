import Foundation

struct VersionCheckResponse: Decodable {
    let updateRequired: Bool
    let latestVersion: String
    let minVersion: String
    let storeUrl: String
    let message: String
    let isMaintenance: Bool

    enum CodingKeys: String, CodingKey {
        case updateRequired  = "update_required"
        case latestVersion   = "latest_version"
        case minVersion      = "min_version"
        case storeUrl        = "store_url"
        case message
        case isMaintenance   = "is_maintenance"
    }
}

@Observable
class VersionCheckService {
    var response: VersionCheckResponse? = nil
    var hasChecked: Bool = false

    func checkVersion() async {
        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
        #if DEBUG
        print("[VersionCheck] Sending version: \(version)")
        #endif
        guard let url = URL(string: "https://api.omidsprivatehub.tech/v1/version/check?version=\(version)") else {
            hasChecked = true
            return
        }

        do {
            let (data, urlResponse) = try await URLSession.shared.data(from: url)
            let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? -1
            #if DEBUG
            let rawBody = String(data: data, encoding: .utf8) ?? "<unreadable>"
            print("[VersionCheck] HTTP \(statusCode) — \(rawBody)")
            #endif
            if statusCode == 200 {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(VersionCheckResponse.self, from: data)
                #if DEBUG
                print("[VersionCheck] updateRequired=\(decoded.updateRequired) isMaintenance=\(decoded.isMaintenance)")
                #endif
                response = decoded
            }
        } catch {
            #if DEBUG
            print("[VersionCheck] Error: \(error)")
            #endif
            // Fail open — leave response = nil so the app proceeds normally
        }

        hasChecked = true
    }
}
