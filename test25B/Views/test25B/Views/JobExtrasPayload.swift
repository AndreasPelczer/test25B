import SwiftUI
import CoreData

// MARK: - Auftrag Extras JSON (pro Auftrag)
struct JobExtrasPayload: Codable {
    var trainingMode: Bool = true
    var checklist: [JobChecklistItem] = []
    var pinnedProductIDs: [String] = []
    var pinnedLexikonCodes: [String] = []
}

struct JobChecklistItem: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var isDone: Bool = false
}

// MARK: - AuftragDetailView
struct AuftragDetailView: View {
    @Environment(\.managedObjectContext) private var ctx
    @ObservedObject var job: Auftrag

    @State private var extras = JobExtrasPayload()
    @State private var newStepText: String = ""
    @State private var showingKnowledgeSheet = false

    private var doneCount: Int { extras.checklist.filter { $0.isDone }.count }
    private var totalCount: Int { extras.checklist.count }
    private var progress: Double { totalCount == 0 ? 0 : Double(doneCount) / Double(totalCount) }

    // Title: bei dir gibt es offenbar kein job.title -> wir nehmen Details/Mitarbeiter/Default
    private var displayTitle: String {
        if let d = job.processingDetails, !d.isEmpty { return d }
        if let n = job.employeeName, !n.isEmpty { return "Auftrag für \(n)" }
        return "Auftrag"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                trainingCard
                checklistCard
                knowledgeCard
                Spacer(minLength: 8)
            }
            .padding()
        }
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingKnowledgeSheet = true
                } label: {
                    Image(systemName: "books.vertical")
                }
            }
        }
        .onAppear {
            extras = loadExtras()
        }
        .sheet(isPresented: $showingKnowledgeSheet) {
            // Achtung: KnowledgePinSheet darf nur EINMAL im Projekt existieren!
            KnowledgePinSheet(
                pinnedProductIDs: $extras.pinnedProductIDs,
                pinnedLexikonCodes: $extras.pinnedLexikonCodes,
                onSave: {
                    saveExtras(extras)
                }
            )
            .environment(\.managedObjectContext, ctx) // ✅ korrekt
        }
    }

    // MARK: - UI Cards

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayTitle)
                        .font(.title2.bold())

                    HStack(spacing: 10) {
                        if let emp = job.employeeName, !emp.isEmpty {
                            Label(emp, systemImage: "person.fill")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Label(job.isCompleted ? "Fertig" : "Offen",
                              systemImage: job.isCompleted ? "checkmark.seal.fill" : "clock")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.headline.monospacedDigit())
                    Text("Schritte")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: progress)

            HStack {
                Text("\(doneCount)/\(totalCount) erledigt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Pins: \(extras.pinnedProductIDs.count + extras.pinnedLexikonCodes.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var trainingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🎓 Ausbildungsmodus")
                    .font(.headline)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { extras.trainingMode },
                    set: { newValue in
                        extras.trainingMode = newValue
                        saveExtras(extras)
                    }
                ))
                .labelsHidden()
            }

            Text(extras.trainingMode
                 ? "AN: Schritt-für-Schritt. Ideal für neue Mitarbeiter."
                 : "AUS: Profi-Modus. Kompakt, schneller Ablauf.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("✅ Schritte / SOP")
                    .font(.headline)
                Spacer()

                Menu {
                    Button("Vorlage: GN + Trennfett + Belegung") { addTemplateGNBlech() }
                    Divider()
                    Button(role: .destructive) {
                        extras.checklist.removeAll()
                        saveExtras(extras)
                    } label: {
                        Label("Leeren", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "wand.and.stars")
                }
            }

            HStack(spacing: 10) {
                TextField("Neuer Schritt…", text: $newStepText)
                    .textFieldStyle(.roundedBorder)

                Button {
                    addStep(newStepText)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .disabled(newStepText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if extras.checklist.isEmpty {
                Text("Noch keine Schritte. Nutze eine Vorlage oder füge Schritte hinzu.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                VStack(spacing: 8) {
                    ForEach(extras.checklist) { item in
                        stepRow(item)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func stepRow(_ item: JobChecklistItem) -> some View {
        HStack(spacing: 12) {
            Button {
                toggleStep(item.id)
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(extras.trainingMode ? .title2 : .title3)
            }

            Text(item.title)
                .font(extras.trainingMode ? .body : .callout)
                .strikethrough(item.isDone)
                .foregroundStyle(item.isDone ? .secondary : .primary)

            Spacer()

            // Löschen im Profi-Modus (optional)
            if !extras.trainingMode {
                Button(role: .destructive) {
                    deleteStep(item.id)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, extras.trainingMode ? 12 : 8)
        .padding(.horizontal, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var knowledgeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📚 Wissen (pro Auftrag)")
                    .font(.headline)
                Spacer()
                Button {
                    showingKnowledgeSheet = true
                } label: {
                    Image(systemName: "pin.fill")
                }
            }

            // Diese Views müssen existieren, aber nur EINMAL im Projekt definiert sein:
            PinnedProductsSection(productIDs: extras.pinnedProductIDs)
                .environment(\.managedObjectContext, ctx)

            PinnedLexikonSection(codes: extras.pinnedLexikonCodes)
                .environment(\.managedObjectContext, ctx)

            Text("Pins sind verlinkte Produkte/Lexikon-Einträge, die zur SOP gehören.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Data: load/save extras

    private func loadExtras() -> JobExtrasPayload {
        guard let s = job.extras, let data = s.data(using: .utf8) else { return JobExtrasPayload() }
        return (try? JSONDecoder().decode(JobExtrasPayload.self, from: data)) ?? JobExtrasPayload()
    }

    private func saveExtras(_ payload: JobExtrasPayload) {
        do {
            let data = try JSONEncoder().encode(payload)
            job.extras = String(data: data, encoding: .utf8)
            try ctx.save()
        } catch {
            print("❌ Auftrag extras save error: \(error)")
        }
    }

    // MARK: - Checklist actions

    private func addStep(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        extras.checklist.append(JobChecklistItem(title: t))
        newStepText = ""
        saveExtras(extras)
    }

    private func toggleStep(_ id: String) {
        guard let idx = extras.checklist.firstIndex(where: { $0.id == id }) else { return }
        extras.checklist[idx].isDone.toggle()
        saveExtras(extras)
    }

    private func deleteStep(_ id: String) {
        extras.checklist.removeAll { $0.id == id }
        saveExtras(extras)
    }

    // MARK: - Template

    private func addTemplateGNBlech() {
        let steps = [
            "GN-Blech 1/1 schwarz vom Hortenwagen nehmen",
            "GN-Blech dünn mit Trennfett besprühen",
            "Falafelbällchen getrennt (Abstand!) auflegen",
            "Blech beschriften (Datum / Charge / Allergene)",
            "In Hortenwagen einhängen",
            "Hortenwagen in KH3 abstellen",
            "Foto machen (RCA-ready) und final abhaken"
        ]
        for s in steps {
            extras.checklist.append(JobChecklistItem(title: s))
        }
        saveExtras(extras)
    }
}
