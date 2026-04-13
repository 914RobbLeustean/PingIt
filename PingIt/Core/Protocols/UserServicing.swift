protocol UserServicing {
    func createUserProfile(_ user: User) async throws
    func fetchUser(id: String) async throws -> User
    func updateUser(id: String, data: [String: Any]) async throws
}
