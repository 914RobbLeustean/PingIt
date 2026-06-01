import SwiftUI

struct TermsOfServiceView: View {
    private let document = LegalDocumentLoader.load("terms")

    var body: some View {
        LegalDocumentView(title: "Terms of Service", document: document)
    }
}
