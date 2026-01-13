//
//  test25B
//
//  Created by Andreas Pelczer on 15.12.25.
//
// ViewModels/AddJobViewModel.swift

import Foundation
import CoreData

class AddJobViewModel: ObservableObject {
    private var viewContext: NSManagedObjectContext
    var event: Event // Das Event, dem der neue Job zugeordnet wird
    
    // Die @Published Properties spiegeln die @State Variablen aus der View wider
    @Published var employeeName: String = ""
    @Published var jobStatus: JobStatus = .pending
    @Published var storageLocation: String
    @Published var processingDetails: String = ""
    @Published var isHotDelivery: Bool = false
    @Published var storageNote: String

    // Globale Konstanten (könnten in einen separaten Service verschoben werden, bleiben hier aber für die Einfachheit)
    let storageLocations = [
        "FischKühlhaus", "Molkerei", "Fleisch", "Bereitstelle",
        "VorkühlerFk", "TK OG", "TK Fingerfood", "TK Logistik Nord"
    ]
    let storageNotes = [
        "1/1 Schwarz", "1/1 Silber", "1/2 Schwarz", "1/2 Silber",
        "1/1 Silber 10er", "1/1 Silber 6,5 cm", "30cm 1/2 Silber 10,30"
    ]

    init(event: Event, context: NSManagedObjectContext) {
        self.event = event
        self.viewContext = context
        
        // Initialisiere die Picker-Werte
        self.storageLocation = storageLocations[0]
        self.storageNote = storageNotes[0]
    }
    
    /**
     * 💾 Erstellt ein neues Core Data Objekt 'Auftrag' und speichert es im Kontext.
     *
     * @return True, wenn der Speichervorgang erfolgreich war.
     */
    func saveNewJob() -> Bool {
        // Kommentar: Erstellung des Core Data Objekts im Context
        let newJob = Auftrag(context: viewContext)
        
        // Kommentar: Zuweisung der UI-Daten aus dem ViewModel
        newJob.employeeName = employeeName
        newJob.storageLocation = storageLocation
        newJob.processingDetails = processingDetails
        newJob.deliveryTemperature = isHotDelivery
        newJob.storageNote = storageNote
        
        // Kommentar: Status- und Abschluss-Logik
        newJob.status = jobStatus
        newJob.isCompleted = (jobStatus == .completed)
        
        // Kommentar: Zuordnung zum Event
        newJob.event = self.event
        
        // Kommentar: Standardwerte für den neuen Timer (müssen gesetzt werden)
        newJob.totalProcessingTime = 0.0
        newJob.lastStartTime = nil
        
        do {
            try viewContext.save()
            // Kommentar: Erfolg
            return true
        } catch {
            // Kommentar: Fehlerbehandlung, ohne die App zum Absturz zu bringen
            print("❌ Fehler beim Speichern des neuen Auftrags: \(error.localizedDescription)")
            return false
        }
    }
    
    /**
     * ⚙️ Prüft, ob der Speichern-Button aktiviert werden soll.
     *
     * @return True, wenn der Mitarbeitername nicht leer ist.
     */
    var isSaveButtonDisabled: Bool {
        return employeeName.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
