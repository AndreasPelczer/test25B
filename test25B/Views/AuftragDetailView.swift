import SwiftUI
import CoreData

// MARK: - Master = AuftragExtrasPayload
typealias JobExtrasPayload = AuftragExtrasPayload

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

    /// “Wo bin ich gerade?” -> erster nicht erledigter Schritt
    private var nextOpenStepTitle: String? {
        extras.checklist.first(where: { !$0.isDone })?.title
    }

    private var displayTitle: String {
        if let d = job.processingDetails, !d.isEmpty { return d }
        if let n = job.employeeName, !n.isEmpty { return "Auftrag für \(n)" }
        return "Auftrag"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                modeCard
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
                Button { showingKnowledgeSheet = true } label: {
                    Image(systemName: "books.vertical")
                }
            }
        }
        .onAppear { extras = loadExtras() }
        .sheet(isPresented: $showingKnowledgeSheet) {
            KnowledgePinSheet(
                pinnedProductIDs: $extras.pinnedProductIDs,
                pinnedLexikonCodes: $extras.pinnedLexikonCodes,
                onSave: { saveExtras(extras) }
            )
            .environment(\.managedObjectContext, ctx)
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
                    Text("SOP")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if extras.trainingMode, let next = nextOpenStepTitle, !job.isCompleted {
                Text("➡️ Jetzt: \(next)")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 2)
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

    private var modeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🎓 Modus").font(.headline)
                Spacer()

                Toggle(isOn: Binding(
                    get: { extras.trainingMode },
                    set: { newValue in
                        extras.trainingMode = newValue
                        saveExtras(extras)
                    }
                )) {
                    Text(extras.trainingMode ? "Ausbildung" : "Profi")
                        .font(.subheadline)
                }
                .labelsHidden()
            }

            Text(extras.trainingMode
                 ? "Ausbildung: Jeder Schritt muss abgehakt werden (SOP = Lernmodus)."
                 : "Profi: SOP bleibt sichtbar, aber ein Haken am Ende reicht.")
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
                Text("✅ MEP / Schritte / SOP").font(.headline)
                Spacer()

                Menu {
                    Button("Vorlage: Setzarbeiten (MEP + SOP)") { addTemplateSetzarbeiten() }
                    Button("Vorlage: Spätzle Kantine (MEP + SOP)") { addTemplateSpaetzleKantine() }
                    Divider()
                    Button(role: .destructive) {
                        extras.checklist.removeAll()
                        job.isCompleted = false
                        saveExtras(extras)
                    } label: {
                        Label("Leeren", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "wand.and.stars")
                }
            }

            if extras.trainingMode {
                HStack(spacing: 10) {
                    TextField("Neuer Schritt…", text: $newStepText)
                        .textFieldStyle(.roundedBorder)

                    Button { addStep(newStepText) } label: {
                        Image(systemName: "plus.circle.fill").font(.title3)
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
                            trainingStepRow(item)
                        }
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Button { markJobCompleted() } label: {
                        Label(job.isCompleted ? "Auftrag ist fertig" : "Auftrag fertig",
                              systemImage: job.isCompleted ? "checkmark.seal.fill" : "checkmark.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) { resetCompletion() } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!job.isCompleted)
                }

                if extras.checklist.isEmpty {
                    Text("Keine SOP hinterlegt.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    DisclosureGroup("SOP anzeigen (\(extras.checklist.count))") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(extras.checklist) { item in
                                proStepRow(item)
                            }
                        }
                        .padding(.top, 6)
                    }
                    .padding(.top, 6)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func trainingStepRow(_ item: AuftragChecklistItem) -> some View {
        HStack(spacing: 12) {
            Button { toggleStep(item.id) } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
            }

            Text(item.title)
                .strikethrough(item.isDone)
                .foregroundStyle(item.isDone ? .secondary : .primary)

            Spacer()

            Button(role: .destructive) { deleteStep(item.id) } label: {
                Image(systemName: "trash").foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func proStepRow(_ item: AuftragChecklistItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "text.badge.checkmark")
                .foregroundStyle(.secondary)
            Text(item.title)
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var knowledgeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📚 Wissen (pro Auftrag)").font(.headline)
                Spacer()
                Button { showingKnowledgeSheet = true } label: {
                    Image(systemName: "pin.fill")
                }
            }

            PinnedProductsSection(productIDs: extras.pinnedProductIDs)
                .environment(\.managedObjectContext, ctx)

            PinnedLexikonSection(codes: extras.pinnedLexikonCodes)
                .environment(\.managedObjectContext, ctx)

            Text("Pins sind Quick-Links (Produkte/Lexikon), die zur SOP gehören.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Data: load/save extras (Master-Typ verwenden!)

    private func loadExtras() -> AuftragExtrasPayload {
        guard let s = job.extras, let data = s.data(using: .utf8) else { return AuftragExtrasPayload() }
        return (try? JSONDecoder().decode(AuftragExtrasPayload.self, from: data)) ?? AuftragExtrasPayload()
    }

    private func saveExtras(_ payload: AuftragExtrasPayload) {
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
        extras.checklist.append(AuftragChecklistItem(title: t))
        newStepText = ""
        job.isCompleted = false
        saveExtras(extras)
    }

    private func toggleStep(_ id: String) {
        guard let idx = extras.checklist.firstIndex(where: { $0.id == id }) else { return }
        extras.checklist[idx].isDone.toggle()

        let allDone = !extras.checklist.isEmpty && extras.checklist.allSatisfy { $0.isDone }
        job.isCompleted = allDone

        saveExtras(extras)
    }

    private func deleteStep(_ id: String) {
        extras.checklist.removeAll { $0.id == id }

        let allDone = !extras.checklist.isEmpty && extras.checklist.allSatisfy { $0.isDone }
        job.isCompleted = allDone

        saveExtras(extras)
    }

    private func markJobCompleted() {
        job.isCompleted = true
        for i in extras.checklist.indices {
            extras.checklist[i].isDone = true
        }
        saveExtras(extras)
    }

    private func resetCompletion() {
        job.isCompleted = false
        for i in extras.checklist.indices {
            extras.checklist[i].isDone = false
        }
        saveExtras(extras)
    }

    // MARK: - Templates

    private func addTemplateSetzarbeiten() {
        let steps = [
            "MEP: Weg & Station prüfen (Küchenbereich 2)",
            "MEP: GN-Bleche 1/1 bereitstellen (wo genau?)",
            "MEP: Etiketten / Stift / Klebeband bereitstellen",
            "MEP: Handschuhe / Tücher / Reiniger checken",
            "SOP: Ware holen (Menge + Charge prüfen)",
            "SOP: Bleche belegen (Raster/Abstände nach Standard)",
            "SOP: Beschriften (Datum / Uhrzeit / Allergene / Charge)",
            "SOP: In Kühlkette zurück (Ziel-KH + Stellplatz)",
            "SOP: Übergabe markieren (Auftrag übergabefähig)",
            "SOP: Foto (optional) für Kontrolle/Referenz)"
        ]
        extras.checklist.append(contentsOf: steps.map { AuftragChecklistItem(title: $0) })
        job.isCompleted = false
        saveExtras(extras)
    }

    private func addTemplateSpaetzleKantine() {
        let steps = [
            "MEP: Pfanne/Kipper + Fett/Butter bereitstellen",
            "MEP: GN 1/1 6,5 cm bereitstellen (Ziel: 5 cm hoch pro Blech)",
            "MEP: Hortenwagen 15 bereitstellen & prüfen",
            "MEP: Wege klären: Produktionsküche -> Kantine",
            "SOP: Spätzle in Butter leicht anbraten (Standard)",
            "SOP: Auf GN 1/1 füllen (ca. 5 cm hoch), gleichmäßig",
            "SOP: In Hortenwagen 15 einhängen",
            "SOP: Ziel-Temperatur prüfen (manuell dokumentieren – später automatisieren)",
            "SOP: In Kantine bringen / Übergabe an Kantinenkoch",
            "SOP: Spülküche Info: Kipper reinigen (später als Auto-Task)"
        ]
        extras.checklist.append(contentsOf: steps.map { AuftragChecklistItem(title: $0) })
        job.isCompleted = false
        saveExtras(extras)
    }
}
