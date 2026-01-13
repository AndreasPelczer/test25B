import SwiftUI
import CoreData

struct JobRowView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var job: Auftrag
    let onJobUpdated: () -> Void

    @StateObject private var viewModel: JobViewModel

    // UI Timer (1s)
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeElapsed: TimeInterval = 0

    @State private var showingEditJobSheet = false

    // ✅ Wichtig: StateObject korrekt initialisieren
    init(job: Auftrag, onJobUpdated: @escaping () -> Void) {
        self.job = job
        self.onJobUpdated = onJobUpdated

        // bevorzugt: context vom Job, sonst globaler Context (falls job frisch/ungewöhnlich ist)
        let ctx = job.managedObjectContext ?? PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: JobViewModel(job: job, context: ctx))
    }

    var body: some View {
        NavigationLink {
            AuftragDetailView(job: job)
        } label: {
            rowContent
        }
        .buttonStyle(.plain)
        .onReceive(timer) { date in
            if viewModel.job.status == .inProgress {
                timeElapsed = viewModel.calculateCurrentTotalTime(currentDate: date)
            }
        }
        .onAppear {
            timeElapsed = viewModel.calculateCurrentTotalTime()
        }
        .sheet(isPresented: $showingEditJobSheet, onDismiss: onJobUpdated) {
            EditJobView(job: viewModel.job)
        }
    }

    // MARK: - Row UI (dein bisheriger Inhalt sauber strukturiert)
    private var rowContent: some View {
        HStack(spacing: 12) {

            // 1) Status-Indikator
            Image(systemName: statusIcon(for: viewModel.job))
                .foregroundColor(statusColor(viewModel.job.status))
                .font(.title2)

            // 2) Infos links
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.job.employeeName ?? "Mitarbeiter fehlt")
                    .font(.headline)
                    .strikethrough(viewModel.job.isCompleted)

                HStack(spacing: 8) {
                    Text(viewModel.job.status.rawValue)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor(viewModel.job.status).opacity(0.15))
                        .cornerRadius(6)

                    if let details = viewModel.job.processingDetails, !details.isEmpty {
                        Text(details)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // 3) Timer + Lagerort
            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.formattedTime(totalSeconds: timeElapsed))
                    .font(.caption)
                    .foregroundColor(viewModel.job.status == .inProgress ? .orange : .secondary)
                    .monospacedDigit()

                if let location = viewModel.job.storageLocation, !location.isEmpty {
                    Text("(\(location))")
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 4) Menü rechts (Status/Bearbeiten/Löschen)
            Menu {
                Section("Status ändern") {

                    if viewModel.job.status != .inProgress {
                        let label = (viewModel.job.status == .onHold) ? "▶️ Pause beenden" : "🚀 Arbeit starten"
                        Button {
                            viewModel.setStatus(.inProgress)
                        } label: {
                            Label(label, systemImage: "play.circle")
                        }
                    }

                    if viewModel.job.status != .onHold {
                        Button {
                            viewModel.setStatus(.onHold)
                        } label: {
                            Label("⏸️ Pausieren", systemImage: "pause.circle")
                        }
                    }

                    if viewModel.job.status != .pending {
                        Button {
                            viewModel.setStatus(.pending)
                        } label: {
                            Label("↩️ Zurücksetzen (Neu)", systemImage: "arrow.uturn.backward.circle")
                        }
                    }

                    if viewModel.job.status != .completed {
                        Button {
                            viewModel.setStatus(.completed)
                        } label: {
                            Label("✅ Abschließen", systemImage: "checkmark.circle.fill")
                        }
                    }
                }

                Divider()

                Button {
                    showingEditJobSheet = true
                } label: {
                    Label("✏️ Bearbeiten", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    viewModel.deleteJob()
                } label: {
                    Label("🗑️ Löschen", systemImage: "trash")
                }

            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 6)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func statusColor(_ status: JobStatus) -> Color {
        switch status {
        case .pending: return .blue
        case .inProgress: return .orange
        case .onHold: return .red
        case .completed: return .green
        }
    }

    private func statusIcon(for job: Auftrag) -> String {
        if job.isCompleted { return "checkmark.circle.fill" }
        if job.status == .onHold { return "pause.circle.fill" }
        if job.status == .inProgress { return "play.circle.fill" }
        return "circle.fill"
    }
}
