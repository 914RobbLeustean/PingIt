import SwiftUI

enum FontRegistrationCheck {
    /// Asserts that all custom fonts referenced by `SyneWeight` and `DMSansWeight`
    /// were registered successfully by iOS at app launch. DEBUG-only.
    static func run() {
        #if DEBUG
        let expected: [String] = SyneWeight.allCases.map(\.rawValue)
                               + DMSansWeight.allCases.map(\.rawValue)
        let missing = expected.filter { UIFont(name: $0, size: 12) == nil }
        if !missing.isEmpty {
            assertionFailure("Custom fonts failed to register: \(missing.joined(separator: ", "))")
        }
        #endif
    }
}

extension SyneWeight: CaseIterable {}
extension DMSansWeight: CaseIterable {}
