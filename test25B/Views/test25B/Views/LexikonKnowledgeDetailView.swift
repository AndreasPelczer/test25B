import SwiftUI
import CoreData

struct LexikonKnowledgeDetailView: View {
    @ObservedObject var entry: CDLexikonEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // HEADER
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.name ?? "")
                        .font(.title2.bold())

                    if let code = entry.code {
                        Text(code)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let kat = entry.kategorie {
                        Text(kat)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // BESCHREIBUNG
                if let b = entry.beschreibung, !b.isEmpty {
                    knowledgeSection(title: "Beschreibung", text: b)
                }

                // DETAILS
                if let d = entry.details, !d.isEmpty {
                    knowledgeSection(title: "Details", text: d)
                }
            }
            .padding()
        }
        .navigationTitle("Lexikon")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Reusable Section
    @ViewBuilder
    private func knowledgeSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.name ?? "Unbenannt")
                .font(.title2.weight(.bold))

            HStack(spacing: 8) {
                if let code = entry.code, !code.isEmpty {
                    Badge(text: code, systemImage: "number")
                }
                if let kat = entry.kategorie, !kat.isEmpty {
                    Badge(text: kat, systemImage: "folder.fill")
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}
