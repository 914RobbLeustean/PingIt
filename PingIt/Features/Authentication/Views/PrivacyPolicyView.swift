import SwiftUI

struct PrivacyPolicyView: View {
    private let document = LegalDocumentLoader.load("privacy")

    var body: some View {
        LegalDocumentView(title: "Privacy Policy", document: document)
    }
}
