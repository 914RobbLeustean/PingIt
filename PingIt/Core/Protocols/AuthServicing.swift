protocol AuthServicing {
    var currentUser: (any AuthUserRepresentable)? { get }
    var isLoading: Bool { get }
    func signUp(email: String, password: String, username: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut() throws
    func sendPasswordReset(email: String) async throws
}
