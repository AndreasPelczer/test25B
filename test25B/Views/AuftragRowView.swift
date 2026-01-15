import SwiftUI
import CoreData

struct AuftragRowView: View {
    @Environment(\.managedObjectContext) private var ctx
    @ObservedObject var auftrag: Auftrag
    var onChanged: () -> Void

    // Extras lesen
    private var extras: AuftragExtrasPayload {
        AuftragExtrasPayload.from(auftrag.extras)
    }

    private var checklistDone: Int { extras.checklist.filter { $0.isDone }.count }
    private var checklistTotal: Int { extras.checklist.count }

    private var progress: AuftragProgressData {
        AuftragProgressData(status: auftrag.status, checklistDone: checklistDone, checklistTotal: checklistTotal)
    }

    private var isActive: Bool { auftrag.status == .inProgress }

    /// Titel, passend zu deinem CoreData-Modell (kein `auftrag.title`!)
    private var displayTitle: String {
        if let d = auftrag.processingDetails, !d.isEmpty { return d }
        if let n = auftrag.employeeName, !n.isEmpty { return "Auftrag für \(n)" }
        return "Auftrag"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Kopfzeile
            HStack(spacing: 12) {
                Image(systemName: auftrag.status.iconName)
                    .foregroundStyle(auftrag.status.color)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayTitle)
                        .font(.headline)

                    if let note = auftrag.processingDetails, !note.isEmpty {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                }

                Spacer()

                Text(auftrag.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(auftrag.status.color.opacity(0.15))
                    .foregroundStyle(auftrag.status.color)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            // Mini-Progress
            HStack(spacing: 8) {
                if checklistTotal > 0 {
                    Text("\(checklistDone)/\(checklistTotal)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 42, alignment: .leading)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.10)).frame(height: 6)
                        Capsule()
                            .fill(auftrag.status.color.opacity(0.85))
                            .frame(width: geo.size.width * CGFloat(min(max(progress.ratio, 0), 1)), height: 6)
                    }
                }
                .frame(height: 6)
            }

            // Quick Actions
            HStack(spacing: 10) {
                Button { setStatus(.inProgress) } label: {
                    Image(systemName: "play.fill").frame(width: 34, height: 30)
                }
                .buttonStyle(.bordered)
                .disabled(auftrag.status == .inProgress || auftrag.status == .completed)

                Button { setStatus(.onHold) } label: {
                    Image(systemName: "pause.fill").frame(width: 34, height: 30)
                }
                .buttonStyle(.bordered)
                .disabled(auftrag.status == .pending || auftrag.status == .completed)

                Button { setStatus(.completed) } label: {
                    Image(systemName: "checkmark").frame(width: 34, height: 30)
                }
                .buttonStyle(.borderedProminent)
                .disabled(auftrag.status == .completed)

                Spacer()
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
        .overlay(alignment: .leading) {
            if isActive {
                RoundedRectangle(cornerRadius: 12).fill(Color.accentColor).frame(width: 4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.accentColor.opacity(0.6) : .clear, lineWidth: 1)
        )
        .contextMenu {
            Button("Start") { setStatus(.inProgress) }
            Button("Pause") { setStatus(.onHold) }
            Button("Fertig") { setStatus(.completed) }
            Divider()
            Button(role: .destructive) { delete() } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }

    private func setStatus(_ s: AuftragStatus) {
        auftrag.status = s
        save()
    }

    private func delete() {
        ctx.delete(auftrag)
        save()
    }

    private func save() {
        do {
            try ctx.save()
            onChanged()
        } catch {
            print("❌ Save Fehler: \(error)")
        }
    }
}
