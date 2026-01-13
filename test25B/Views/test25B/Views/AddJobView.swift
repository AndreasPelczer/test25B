// Views/AddJobView.swift (NEU: Reine UI-View)

import SwiftUI
import CoreData

struct AddJobView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    
    // 💡 Das ViewModel hält alle Daten und die save-Logik
    @StateObject var viewModel: AddJobViewModel
    
    // Initializer, um das ViewModel zu erstellen und das Event zu übergeben
    init(event: Event, viewContext: NSManagedObjectContext) {
        // Kommentar: ViewModel wird beim Initialisieren der View erstellt
        _viewModel = StateObject(wrappedValue: AddJobViewModel(event: event, context: viewContext))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Kommentar: Bindung an die @Published Properties des ViewModels
                    TextField("Mitarbeitername", text: $viewModel.employeeName)
                    
                    // Picker für Status
                    Picker("Status", selection: $viewModel.jobStatus) {
                        ForEach(JobStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Picker für Lagerort
                    Picker("Lagerort auswählen", selection: $viewModel.storageLocation) {
                        // Kommentar: Greift auf die Daten des ViewModels zu
                        ForEach(viewModel.storageLocations, id: \.self) { location in
                            Text(location)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Picker für Lagerhinweis
                    Picker("Lagerhinweis", selection: $viewModel.storageNote) {
                        ForEach(viewModel.storageNotes, id: \.self) { note in
                            Text(note)
                        }
                    }
                    .pickerStyle(.menu)
                    
                } header: {
                    Text("Zuweisung & Ort")
                }
                
                Section {
                    TextEditor(text: $viewModel.processingDetails)
                        .frame(minHeight: 100)
                        .overlay(
                            Text("Detaillierte Anweisung (z.B. '12 auf 1/1 Blech')")
                                .foregroundColor(.gray)
                                // Kommentar: Opazität nutzt die ViewModel Property
                                .opacity(viewModel.processingDetails.isEmpty ? 1 : 0)
                                .padding(.top, 8)
                                .padding(.leading, 4),
                            alignment: .topLeading
                        )
                    
                    Toggle("Heiß ausliefern?", isOn: $viewModel.isHotDelivery)
                    
                } header: {
                    Text("Verarbeitung und Auslieferung")
                }
            }
            // Kommentar: Der Event-Titel wird über das ViewModel aus dem Event geholt
            .navigationTitle("Neuer Auftrag für \(viewModel.event.title ?? "Event")")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        if viewModel.saveNewJob() { // Kommentar: Speichern-Logik liegt im ViewModel
                            dismiss()
                        }
                    }
                    // Kommentar: Deaktivierung nutzt die ViewModel Logik
                    .disabled(viewModel.isSaveButtonDisabled)
                }
            }
        }
    }
}
