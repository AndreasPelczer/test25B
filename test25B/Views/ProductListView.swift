//
//  ProductListView.swift
//  test25B
//
//  Created by Andreas Pelczer on 13.01.26.
//


import SwiftUI
import CoreData

struct ProductListView: View {
    @FetchRequest private var products: FetchedResults<CDProduct>

    private let searchText: String
    private let category: String

    init(searchText: String, category: String) {
        self.searchText = searchText
        self.category = category

        let predicate = ProductListView.makePredicate(searchText: searchText, category: category)

        _products = FetchRequest(
            entity: CDProduct.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \CDProduct.category, ascending: true),
                NSSortDescriptor(keyPath: \CDProduct.name, ascending: true)
            ],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        List {
            if products.isEmpty {
                EmptyStateView(
                    title: "Keine Produkte",
                    subtitle: "Passe Suche oder Kategorie an."
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(products, id: \.objectID) { product in
                    NavigationLink(destination: ProductKnowledgeDetailView(product: product)) {
                        ProductKnowledgeRow(product: product)
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
            preds.append(NSPredicate(format: "category == %@", category))
        }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            preds.append(NSPredicate(format: "(name CONTAINS[cd] %@) OR (category CONTAINS[cd] %@) OR (dataSource CONTAINS[cd] %@)", q, q, q))
        }

        if preds.isEmpty { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: preds)
    }
}
