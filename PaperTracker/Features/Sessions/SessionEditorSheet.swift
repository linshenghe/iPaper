import SwiftUI

/// Minimal editor for manual sessions — edit note only.
struct SessionEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataStore: DataStore
    let session: Session

    @State private var note: String
    @State private var showDelete = false

    init(dataStore: DataStore, session: Session) {
        self.dataStore = dataStore
        self.session = session
        _note = State(initialValue: session.note)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit Session")
                    .font(AppTypography.windowTitle)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.sheetPadding)
            .padding(.vertical, AppSpacing.space8)

            VStack(alignment: .leading, spacing: AppSpacing.formSectionGap) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target").font(AppTypography.fieldLabel)
                    Text(session.targetName).font(AppTypography.bodyPrimary)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration").font(AppTypography.fieldLabel)
                        Text(DateFormatting.formatTimer(session.durationSeconds))
                            .font(AppTypography.timerText)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Source").font(AppTypography.fieldLabel)
                        Text(session.source == .timer ? "Timer" : "Manual")
                            .font(AppTypography.bodyPrimary)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Note").font(AppTypography.fieldLabel)
                    TextEditor(text: $note)
                        .font(AppTypography.bodyPrimary)
                        .frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: AppRadius.control)
                            .stroke(AppColors.lineSubtle))
                }
            }
            .padding(AppSpacing.sheetPadding)

            HStack {
                Button("Delete", role: .destructive) {
                    dataStore.appData.sessions.removeAll { $0.id == session.id }
                    try? dataStore.save()
                    dismiss()
                }
                Spacer()
                Button("Cancel") { dismiss() }
                PrimaryButton(title: "Save") {
                    if let idx = dataStore.appData.sessions.firstIndex(where: { $0.id == session.id }) {
                        dataStore.appData.sessions[idx].note = note
                        try? dataStore.save()
                    }
                    dismiss()
                }
            }
            .padding(.horizontal, AppSpacing.sheetPadding)
            .padding(.vertical, AppSpacing.space8)
        }
        .frame(minWidth: 400, idealWidth: 420, minHeight: 320)
    }
}
