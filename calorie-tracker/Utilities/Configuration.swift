import Foundation

enum Configuration {
    static let openAIAPIKey: String = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["OPENAI_API_KEY"] as? String else {
            fatalError("Missing Secrets.plist or OPENAI_API_KEY. Add your key to Secrets.plist in the source directory.")
        }
        return key
    }()
}
