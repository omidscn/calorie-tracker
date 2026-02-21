import Foundation
import Supabase
import Auth

private let supabaseAnonKey: String = {
    guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
          let dict = NSDictionary(contentsOfFile: path),
          let key = dict["SUPABASE_ANON_KEY"] as? String else {
        #if DEBUG
        print("⚠️ Missing Secrets.plist or SUPABASE_ANON_KEY — auth will fail")
        #endif
        return ""
    }
    return key
}()

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://omidsprivatehub.tech")!,
    supabaseKey: supabaseAnonKey,
    options: .init(
        auth: .init(
            emitLocalSessionAsInitialSession: true
        )
    )
)
