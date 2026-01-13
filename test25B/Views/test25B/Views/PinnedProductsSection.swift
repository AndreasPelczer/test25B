import SwiftUI
import CoreData

// MARK: - Gepinnte Produkte
struct PinnedProductsSection: View {
    @Environment(\.managedObjectContext) private var ctx
    let productIDs: [String]

    var body: some View {
        if productIDs.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Produkte")
                    .font(.subheadline.bold())

                ForEach(productIDs, id: \.self) { id in
                    Text("• Produkt-ID: \(id)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Gepinntes Lexikon
struct PinnedLexikonSection: View {
    @Environment(\.managedObjectContext) private var ctx
    let codes: [String]

    var body: some View {
        if codes.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Lexikon")
                    .font(.subheadline.bold())

                ForEach(codes, id: \.self) { code in
                    Text("• \(code)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
