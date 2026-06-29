import SwiftUI

struct ReviewEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataStore: DataStore
    let existingReview: Review?

    @State private var journal: String
    @State private var status: ReviewStatus
    @State private var deadline: Date?
    @State private var note: String
    @State private var hasDeadline: Bool
    @State private var showDirtyAlert = false
    @State private var validationError: String?

    private var isNew: Bool { existingReview == nil }
    private var isDirty: Bool {
        guard let r = existingReview else {
            return !journal.isEmpty || !note.isEmpty || deadline != nil
        }
        return journal != r.journal || status != r.status || deadline != r.deadline || note != r.note
    }

    init(dataStore: DataStore, existingReview: Review? = nil) {
        self.dataStore = dataStore
        self.existingReview = existingReview
        _journal = State(initialValue: existingReview?.journal ?? "")
        _status = State(initialValue: existingReview?.status ?? .inProgress)
        _deadline = State(initialValue: existingReview?.deadline)
        _note = State(initialValue: existingReview?.note ?? "")
        _hasDeadline = State(initialValue: existingReview?.deadline != nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isNew ? "New Review" : "Edit Review")
                    .font(AppTypography.windowTitle)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.sheetPadding)
            .padding(.vertical, AppSpacing.space8)

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.formSectionGap) {
                    VStack(alignment: .leading, spacing: AppSpacing.fieldGap) {
                        Text("Journal *")
                            .font(AppTypography.fieldLabel)
                        TextField("期刊名称", text: $journal)
                            .textFieldStyle(.roundedBorder)
                        if let err = validationError {
                            Text(err).font(AppTypography.metaLabel).foregroundColor(AppColors.danger)
                        }
                    }

                    Picker("Status", selection: $status) {
                        Text("In Progress").tag(ReviewStatus.inProgress)
                        Text("Completed").tag(ReviewStatus.completed)
                    }
                    .pickerStyle(.menu)

                    Toggle(isOn: $hasDeadline) {
                        Text("Deadline").font(AppTypography.fieldLabel)
                    }
                    if hasDeadline {
                        DatePicker("", selection: Binding(
                            get: { deadline ?? Date() }, set: { deadline = $0 }
                        ), displayedComponents: .date)
                        .datePickerStyle(.field)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes").font(AppTypography.fieldLabel)
                        TextEditor(text: $note)
                            .font(AppTypography.bodyPrimary)
                            .frame(minHeight: 60)
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.control)
                                .stroke(AppColors.lineSubtle))
                    }
                }
                .padding(AppSpacing.sheetPadding)
            }

            HStack {
                if !isNew {
                    Button("Delete", role: .destructive) {
                        dataStore.appData.reviews.removeAll { $0.id == existingReview?.id }
                        try? dataStore.save()
                        dismiss()
                    }
                }
                Spacer()
                Button("Cancel") { tryDismiss() }
                PrimaryButton(title: "Save", action: save)
            }
            .padding(.horizontal, AppSpacing.sheetPadding)
            .padding(.vertical, AppSpacing.space8)
            .alert("Discard Changes?", isPresented: $showDirtyAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
        }
        .frame(minWidth: 420, idealWidth: 460, minHeight: 360)
    }

    private func save() {
        guard !journal.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "期刊名不能为空"
            return
        }
        let now = Date()
        if let r = existingReview, let idx = dataStore.appData.reviews.firstIndex(where: { $0.id == r.id }) {
            dataStore.appData.reviews[idx].journal = journal
            dataStore.appData.reviews[idx].status = status
            dataStore.appData.reviews[idx].deadline = hasDeadline ? deadline : nil
            dataStore.appData.reviews[idx].note = note
            dataStore.appData.reviews[idx].updatedAt = now
        } else {
            let review = Review(
                id: UUID().uuidString, journal: journal, deadline: hasDeadline ? deadline : nil,
                status: status, note: note, createdAt: now, updatedAt: now
            )
            dataStore.appData.reviews.append(review)
        }
        try? dataStore.save()
        dismiss()
    }

    private func tryDismiss() {
        if isDirty { showDirtyAlert = true } else { dismiss() }
    }
}
