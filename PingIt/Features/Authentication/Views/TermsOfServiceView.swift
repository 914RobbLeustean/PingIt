import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        WebContentView(htmlFileName: "terms")
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
    }
}
