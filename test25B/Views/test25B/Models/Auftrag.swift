// Models/Auftrag.swift (BEREINIGT)

import Foundation
import CoreData


enum JobStatus: String, CaseIterable, Identifiable {
    case pending = "Offen"
    case inProgress = "In Bearbeitung"
    case onHold = "Pausiert"
    case completed = "Abgeschlossen"
    
    var id: String { self.rawValue } // Damit SwiftUI jedes Element eindeutig erkennt
}
    

extension Auftrag {
    // Hier ist KEINE erneute Deklaration von @NSManaged Eigenschaften!

    // Nur die berechnete Property für den Enum-Zugriff behalten:
    var status: JobStatus {
        get {
            // ... (Ihre Logik, die statusRawValue verwendet)
            return JobStatus(rawValue: statusRawValue ?? JobStatus.pending.rawValue) ?? .pending
        }
        set {
            // ... (Ihre Logik)
            statusRawValue = newValue.rawValue
        }
    }
}

// HINWEIS: Die Basisklasse "Auftrag" wird automatisch von Xcode generiert und
// enthält alle @NSManaged Properties, einschließlich der neuen.
