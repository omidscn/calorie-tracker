import Foundation
import Supabase
import Auth

@Observable
final class AuthService {
    var isAuthenticated = false
    var isLoading = true
    var currentUser: User?
    var errorMessage: String?

    init() {
        Task {
            for await (_, session) in supabase.auth.authStateChanges {
                let validSession = session.flatMap { $0.isExpired ? nil : $0 }
                self.isAuthenticated = validSession != nil
                self.currentUser = validSession?.user
                if self.isLoading {
                    self.isLoading = false
                }
            }
        }
    }

    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async {
        errorMessage = nil
        do {
            try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )

            if let fullName {
                let displayName = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                if !displayName.isEmpty {
                    try await supabase.auth.update(
                        user: UserAttributes(data: ["full_name": .string(displayName)])
                    )
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
