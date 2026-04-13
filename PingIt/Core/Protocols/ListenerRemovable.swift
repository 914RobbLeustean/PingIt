import FirebaseFirestore

/// Wraps a Firestore `ListenerRegistration` so ViewModels and mocks share
/// a concrete type without importing FirebaseFirestore everywhere.
final class ListenerHandle {
    private let onRemove: () -> Void

    init(_ registration: ListenerRegistration) {
        self.onRemove = { registration.remove() }
    }

    /// For use in tests only — supply a custom removal callback.
    init(onRemove: @escaping () -> Void) {
        self.onRemove = onRemove
    }

    func remove() {
        onRemove()
    }
}
