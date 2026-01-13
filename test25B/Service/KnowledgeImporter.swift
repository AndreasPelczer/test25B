import Foundation
import CoreData

enum KnowledgeImporter {

    static func importIfNeeded(into context: NSManagedObjectContext) {
        let productCount = (try? context.count(for: CDProduct.fetchRequest())) ?? 0
        let lexCount = (try? context.count(for: CDLexikonEntry.fetchRequest())) ?? 0

        if productCount > 0 || lexCount > 0 {
            print("ℹ️ Knowledge Import: Daten vorhanden (Products: \(productCount), Lexikon: \(lexCount)). Skip.")
            return
        }

        importProducts(into: context)
        importLexikon(into: context)

        do {
            try context.save()
            print("🚀 Knowledge Import abgeschlossen.")
        } catch {
            print("🚨 Save Fehler nach Import: \(error)")
        }
    }

    // MARK: - Produkte

    private static func importProducts(into context: NSManagedObjectContext) {
        guard let url = Bundle.main.url(forResource: "Produkte", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("🚨 Produkte.json nicht gefunden.")
            return
        }

        do {
            let decoded = try JSONDecoder().decode([JSONProduct].self, from: data)

            // ✅ FIX: kein "objects:" Initializer -> keine Placeholders mehr
            var index = 0
            let productInsert = NSBatchInsertRequest(
                entityName: "CDProduct",
                managedObjectHandler: { managedObject in
                    guard index < decoded.count else { return true }
                    let jsonP = decoded[index]
                    index += 1

                    let obj = managedObject as! CDProduct
                    obj.id = jsonP.id
                    obj.name = jsonP.name
                    obj.category = jsonP.kategorie
                    obj.dataSource = jsonP.typ
                    obj.beschreibung = jsonP.beschreibung

                    if let meta = jsonP.metadata {
                        obj.allergene = meta.allergene
                        obj.zusatzstoffe = meta.zusatzstoffe
                        obj.kcal = meta.kcal_100g
                        obj.fett = meta.fett
                        obj.zucker = meta.zucker
                    }

                    obj.stockQuantity = 0
                    obj.stockUnit = "Stk."

                    if let rezept = jsonP.rezept {
                        obj.portionen = rezept.portionen
                        obj.algorithmusText = rezept.algorithmus.joined(separator: "\n")
                    }

                    return false
                }
            )
            productInsert.resultType = .statusOnly

            _ = try context.execute(productInsert)

            // Ingredients separat (Relationship)
            let ids = decoded.map { $0.id }
            let fetch: NSFetchRequest<CDProduct> = CDProduct.fetchRequest()
            fetch.predicate = NSPredicate(format: "id IN %@", ids)
            fetch.fetchBatchSize = 500

            let products = try context.fetch(fetch)

            // ✅ Robust: crasht nicht bei doppelten IDs
            var byId: [String: CDProduct] = [:]
            for p in products {
                guard let id = p.id else { continue }
                if byId[id] == nil {
                    byId[id] = p
                } else {
                    print("⚠️ Duplicate Product ID gefunden: \(id)")
                }
            }



            for p in decoded {
                guard let rezept = p.rezept else { continue }
                guard let cdProduct = byId[p.id] else { continue }

                for ing in rezept.komponenten {
                    let i = CDIngredient(context: context)
                    i.name = ing.name
                    i.menge = ing.menge
                    i.einheit = ing.einheit
                    i.product = cdProduct
                }
            }

            print("✅ Produkte geladen: \(decoded.count)")
        } catch {
            print("🚨 Parse Fehler Produkte.json: \(error)")
        }
    }

    // MARK: - Lexikon

    private static func importLexikon(into context: NSManagedObjectContext) {
        guard let url = Bundle.main.url(forResource: "Lexikon", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("🚨 Lexikon.json nicht gefunden.")
            return
        }

        do {
            let raw = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []

            // ✅ FIX: kein "objects:" Initializer -> keine Placeholders mehr
            var index = 0
            let insert = NSBatchInsertRequest(
                entityName: "CDLexikonEntry",
                managedObjectHandler: { managedObject in
                    guard index < raw.count else { return true }
                    let e = raw[index]
                    index += 1

                    let code = (e["code"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let name = (e["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                    if code.isEmpty || name.isEmpty { return false }

                    let obj = managedObject as! CDLexikonEntry
                    obj.code = code
                    obj.name = name
                    obj.kategorie = (e["kategorie"] as? String) ?? "Fachbuch"
                    obj.beschreibung = (e["beschreibung"] as? String) ?? ""
                    obj.details = (e["details"] as? String) ?? ""

                    return false
                }
            )
            insert.resultType = .statusOnly

            _ = try context.execute(insert)
            print("📚 Lexikon geladen: \(raw.count)")
        } catch {
            print("🚨 Parse Fehler Lexikon.json: \(error)")
        }
    }
}
