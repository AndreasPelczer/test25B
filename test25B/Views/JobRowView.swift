// Views/JobRowView.swift (NEU: Reine UI-View)

import SwiftUI
import CoreData

struct JobRowView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    @StateObject var viewModel: JobViewModel
    var onJobUpdated: () -> Void    // Combine-Timer für die UI-Aktualisierung (bleibt in der View)
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeElapsed: TimeInterval = 0
    
    @State private var showingEditJobSheet = false
    
    init(job: Auftrag, onJobUpdated: @escaping () -> Void) {
            _viewModel = StateObject(wrappedValue: JobViewModel(job: job, context: job.managedObjectContext!))
            self.onJobUpdated = onJobUpdated // Setze die Closure
        }
    
    // Helper-Funktion für die farbliche Kennzeichnung (bleibt in der View)
    private func statusColor(_ status: JobStatus) -> Color {
        // Kommentar: Hier wird die Farbe basierend auf dem JobStatus gesetzt.
        switch status {
        case .pending: return .blue
        case .inProgress: return .orange
        case .onHold: return .red
        case .completed: return .green
        }
    }
    
    // JobRowView.swift (KORRIGIERTER BODY)

    var body: some View {
        HStack {
            // MARK: - 1. Status-Indikator
            Image(systemName: viewModel.job.isCompleted ? "checkmark.circle.fill" : viewModel.job.status == .onHold ? "pause.circle.fill" : "circle.fill")
                .foregroundColor(statusColor(viewModel.job.status))
                .font(.title2)
              
            // MARK: - 2. Hauptinformationen
            VStack(alignment: .leading) {
                Text(viewModel.job.employeeName ?? "Mitarbeiter fehlt")
                    .font(.headline)
                    .strikethrough(viewModel.job.isCompleted)
                 
                HStack(spacing: 5) {
                    // NEUE STATUSANZEIGE
                    Text(viewModel.job.status.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor(viewModel.job.status).opacity(0.15))
                        .cornerRadius(4)
                     
                    // Details
                    if let details = viewModel.job.processingDetails, !details.isEmpty {
                        Text(details)
                            .lineLimit(1)
                            .font(.subheadline)
                    }
                }
            }
              
            Spacer()
              
            // MARK: - 3. TIMER ANZEIGE
            VStack(alignment: .trailing) {
                // ... (Timer-Logik bleibt unverändert)
                Text(viewModel.formattedTime(totalSeconds: timeElapsed))
                    .font(.caption)
                    .foregroundColor(viewModel.job.status == .inProgress ? .orange : .secondary)
                    .monospacedDigit()
                 
                // Lagerort
                if let location = viewModel.job.storageLocation, !location.isEmpty {
                    Text("(\(location))")
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onReceive(timer) { date in
                if viewModel.job.status == .inProgress {
                    timeElapsed = viewModel.calculateCurrentTotalTime(currentDate: date)
                }
            }
            .onAppear {
                timeElapsed = viewModel.calculateCurrentTotalTime()
            }
              
            // MARK: - 4. Dropdown-Menü
            Menu {
                Section("Status ändern") {
                    
                    // 1. Bearbeitung starten / Pause beenden
                    if viewModel.job.status != .inProgress {
                        
                        // Dynamisches Label: Unterscheidet, ob von Pause oder von Offen gestartet wird
                        let label = (viewModel.job.status == .onHold) ? "▶️ Pause beenden" : "🚀 arbeit starten"
                        
                        Button {
                            viewModel.setStatus(.inProgress)
                        } label: {
                            Label(label, systemImage: "play.circle")
                        }
                    }
                    
                    // 2. Pausieren
                    if viewModel.job.status != .onHold {
                        Button { viewModel.setStatus(.onHold) } label: { Label("⏸️ Pausieren", systemImage: "pause.circle") }
                    }
                    
                    // 3. Zurücksetzen (Neu)
                    if viewModel.job.status != .pending {
                        Button { viewModel.setStatus(.pending) } label: { Label("↩️ Zurücksetzen (Neu)", systemImage: "arrow.uturn.backward.circle") }
                    }
                    
                    // 4. Abschließen
                    if viewModel.job.status != .completed {
                        Button { viewModel.setStatus(.completed) } label: { Label("✅ Abschließen", systemImage: "checkmark.circle.fill") }
                    }
                }
                
                Divider()
                
                // Bearbeiten (bleibt außerhalb der Status-Sektion)
                Button {
                    showingEditJobSheet = true
                } label: {
                    Label("✏️ Bearbeiten", systemImage: "pencil")
                }
                
                // Löschen
                Button(role: .destructive) {
                    viewModel.deleteJob()
                } label: {
                    Label("🗑️ Löschen", systemImage: "trash")
                }
                
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
                .onTapGesture {
                    self.showingEditJobSheet = true
                }
                .contentShape(Rectangle())
                .padding(.vertical, 4)
                
                // KORREKTUR: Rufe die Closure auf, wenn das Sheet geschlossen wird
                .sheet(isPresented: $showingEditJobSheet, onDismiss: onJobUpdated) {
                    EditJobView(job: viewModel.job)
                }
            }
        }
    }
