protocol UserServicing {
    func createUserProfile(_ user: User) async throws
    func fetchUser(id: String) async throws -> User
    /// Real-time listener on a user document (live counters, profile edits).
    func observeUser(
        id: String,
        onUpdate: @escaping @Sendable (User?) -> Void
    ) -> ListenerHandle
    func updateUser(id: String, data: [String: Any]) async throws
    func mergeUser(id: String, data: [String: Any]) async throws
    func ensureUserProfileExists(uid: String, email: String) async throws -> User
    func updateUsername(id: String, currentUsername: String?, newUsername: String) async throws
    func isUsernameTaken(_ username: String) async throws -> Bool
}
