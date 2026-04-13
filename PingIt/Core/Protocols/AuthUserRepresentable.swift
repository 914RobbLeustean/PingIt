/// Represents the minimal user identity that ViewModels need from an authenticated session.
/// All ViewModels only access `.uid`, so this avoids a hard dependency on `FirebaseAuth.User`
/// and makes mock users trivial to create in tests.
protocol AuthUserRepresentable {
    var uid: String { get }
}
