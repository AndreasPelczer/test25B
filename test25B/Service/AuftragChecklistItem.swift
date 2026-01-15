import Foundation

// MARK: - Checkliste (ein einzelner Schritt)
struct AuftragChecklistItem: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var isDone: Bool = false
}

// MARK: - Extras Payload (MASTER für Auftrag.extras)
struct AuftragExtrasPayload: Codable {

    /// true = Ausbildungsmodus, false = Profi
    var trainingMode: Bool = true

    /// SOP / Checkliste
    var checklist: [AuftragChecklistItem] = []

    /// Knowledge-Pins
    var pinnedProductIDs: [String] = []
    var pinnedLexikonCodes: [String] = []
}

// MARK: - JSON Helfer für Auftrag.extras (String?)
extension AuftragExtrasPayload {

    static func from(_ extrasString: String?) -> AuftragExtrasPayload {
        guard
            let s = extrasString,
            !s.isEmpty,
            let data = s.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(AuftragExtrasPayload.self, from: data)
        else {
            return AuftragExtrasPayload()
        }
        return decoded
    }

    func toJSONString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Kompatibilität (nur Item-Aliases)
typealias ChecklistItem = AuftragChecklistItem
