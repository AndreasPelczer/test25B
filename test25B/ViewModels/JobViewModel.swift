//
//  test25B
//
//  Created by Andreas Pelczer on 15.12.25.
//
// ViewModels/JobViewModel.swift

import Foundation
import CoreData
import Combine // Für den Timer

// 💡 Dieses ViewModel trennt die Geschäftslogik (Timer, Statuswechsel)
// von der Darstellung (JobRowView).

class JobViewModel: ObservableObject {
    private var viewContext: NSManagedObjectContext
    @Published var job: Auftrag // Das beobachtete Core Data Objekt
    
    // Timer für die UI-Aktualisierung
    // Der Timer wird vom JobRowView über .onReceive(timer) gesteuert.
    
    init(job: Auftrag, context: NSManagedObjectContext) {
        self.job = job
        self.viewContext = context
    }

    // MARK: - Status und Timer Logik

    /**
     * 🔄 Wechselt den Status des Auftrags und persistiert die Laufzeit.
     *
     * @param newStatus Der neue JobStatus (pending, inProgress, onHold, completed).
     */
    // JobViewModel.swift (KORRIGIERTE setStatus FUNKTION)

    // JobViewModel.swift (FINAL KORRIGIERTE setStatus FUNKTION)

    func setStatus(_ newStatus: JobStatus) {
        
        // 1. Speichere die verstrichene Zeit, falls der Job lief
        // Dies geschieht JEDES MAL, wenn wir von .inProgress WEGGEHEN
        if job.status == .inProgress, let lastStart = job.lastStartTime {
            let elapsed = Date().timeIntervalSince(lastStart)
            job.totalProcessingTime += elapsed
        }
        
        // 2. Setze den Startpunkt (Timer-Kontrolle)
        if newStatus == .inProgress {
            // Starte/Setze Timer fort
            job.lastStartTime = Date()
            
        } else {
            // Pausiere/Stoppe Timer (bei .onHold, .pending, .completed)
            job.lastStartTime = nil
        }
        
        // 3. Status setzen und Abschluss-Flag synchronisieren
        job.status = newStatus
        job.isCompleted = (newStatus == .completed)
        
        saveContext()
    }
    
    // MARK: - Datenzugriff und Formatierung (für die UI)
    
    /**
     * ⏲️ Berechnet die aktuelle Gesamtzeit des Auftrags (kumuliert + laufend).
     *
     * @param currentDate Der aktuelle Zeitpunkt (für die Live-Berechnung).
     * @return Die gesamte verstrichene Zeit in Sekunden.
     */
    func calculateCurrentTotalTime(currentDate: Date = Date()) -> TimeInterval {
        var total = job.totalProcessingTime
        
        if job.status == .inProgress, let lastStart = job.lastStartTime {
            total += currentDate.timeIntervalSince(lastStart)
        }
        return total
    }

    /**
     * ⚙️ Formatiert die Zeit von Sekunden in HH:MM:SS.
     */
    func formattedTime(totalSeconds: TimeInterval) -> String {
        let seconds = Int(totalSeconds)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    // MARK: - Core Data CRUD Operationen
    
    func deleteJob() {
        viewContext.delete(job)
        saveContext()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            // ⚠️ Hier wird der Fehler nicht zum Absturz gebracht (kein fatalError),
            // sondern nur geloggt (Bessere Fehlerbehandlung).
            let nsError = error as NSError
            print("❌ UNABLE TO SAVE CONTEXT: \(nsError), \(nsError.userInfo)")
        }
    }
}
