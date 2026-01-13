//
//  LexikonListView.swift
//  test25B
//
//  Created by Andreas Pelczer on 13.01.26.
//


import SwiftUI
import CoreData

struct LexikonListView: View {
    @FetchRequest private var entries: FetchedResults<CDLexikonEntry>

    private let searchText: String
    private let category: String

    init(searchText: String, category: String) {
        self.searchText = searchText
        self.category = category

        let predicate = LexikonListView.makePredicate(searchText: searchText, category: category)

        _entries = FetchRequest(
            entity: CDLexikonEntry.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \CDLexikonEntry.kategorie, ascending: true),
                NSSortDescriptor(keyPath: \CDLexikonEntry.name, ascending: true)
            ],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        List {
            if entries.isEmpty {
                EmptyStateView(
                    title: "Kein Lexikon-Eintrag",
                    subtitle: "Passe Suche oder Kategorie an."
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(entries, id: \.objectID) { entry in
                    NavigationLink(destination: LexikonKnowledgeDetailView(entry: entry)) {
                        LexikonKnowledgeRow(entry: entry)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(PlainListStyle())
        .padding(.top, 6)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }

    private static func makePredicate(searchText: String, category: String) -> NSPredicate? {
        var preds: [NSPredicate] = []

        if category != "Alle" {
            preds.append(NSPredicate(format: "kategorie == %@", category))
        }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            preds.append(NSPredicate(format: "(name CONTAINS[cd] %@) OR (code CONTAINS[cd] %@) OR (kategorie CONTAINS[cd] %@)", q, q, q))
        }

        if preds.isEmpty { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: preds)
    }
}
