import SwiftUI

/// Full editor for creating/editing a paper. Presented as a sheet.
struct PaperEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var dataStore: DataStore
    let existingPaper: Paper?
    let aiPrefill: AISuggestion?

    // MARK: - Form state

    @State private var title: String
    @State private var journal: String
    @State private var status: PaperStatus
    @State private var deadline: Date?
    @State private var note: String
    @State private var hasDeadline: Bool

    @State private var showDeleteConfirmation = false
    @State private var showDirtyAlert = false
    @State private var validationError: String?

    private var isNew: Bool { existingPaper == nil }
    private var isDirty: Bool {
        guard let paper = existingPaper else {
            return !title.isEmpty || !journal.isEmpty || !note.isEmpty || deadline != nil
        }
        return title != paper.title
            || journal != paper.journal
            || status != paper.status
            || deadline != paper.deadline
            || note != paper.note
    }

    init(dataStore: DataStore, existingPaper: Paper? = nil, aiPrefill: AISuggestion? = nil) {
        self.dataStore = dataStore
        self.existingPaper = existingPaper
        self.aiPrefill = aiPrefill

        let baseTitle = existingPaper?.title ?? aiPrefill?.title ?? ""
        let baseJournal = existingPaper?.journal ?? aiPrefill?.journal ?? ""
        let baseNote = existingPaper?.note ?? aiPrefill?.note ?? ""
        let baseStatus: PaperStatus = {
            if let s = existingPaper?.status { return s }
            if let raw = aiPrefill?.status {
                switch raw {
                case "Submitted": return .submitted
                case "R&R": return .rnr
                case "Accepted": return .accepted
                case "Published": return .published
                default: return .writing
                }
            }
            return .writing
        }()
        let baseDeadline: Date? = {
            if let d = existingPaper?.deadline { return d }
            if let raw = aiPrefill?.deadline, !raw.isEmpty {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withFullDate]
                return f.date(from: raw) ?? DateFormatting.displayFormatter.date(from: raw)
            }
            return nil
        }()

        _title = State(initialValue: baseTitle)
        _journal = State(initialValue: baseJournal)
        _status = State(initialValue: baseStatus)
        _deadline = State(initialValue: baseDeadline)
        _note = State(initialValue: baseNote)
        _hasDeadline = State(initialValue: baseDeadline != nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.formSectionGap) {
                    basicInfoSection
                    workTrackingSection
                    notesSection
                }
                .padding(AppSpacing.sheetPadding)
            }

            // Footer
            footer
        }
        .frame(minWidth: 480, idealWidth: 520, minHeight: 500, idealHeight: 600)
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Text(isNew ? "New Paper" : (existingPaper?.title ?? "Edit Paper"))
                .font(AppTypography.windowTitle)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.sheetPadding)
        .padding(.vertical, AppSpacing.space8)
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.fieldGap) {
            SectionHeader("Basic Info")

            FieldLabel("Title *")
            TextField("论文标题", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(AppTypography.bodyPrimary)
            if let error = validationError {
                Text(error)
                    .font(AppTypography.metaLabel)
                    .foregroundColor(AppColors.danger)
            }

            FieldLabel("Journal")
            TextField("期刊名称", text: $journal)
                .textFieldStyle(.roundedBorder)
                .font(AppTypography.bodyPrimary)

            FieldLabel("Status")
            Picker("", selection: $status) {
                ForEach(PaperStatus.allCases, id: \.rawValue) { s in
                    HStack {
                        Circle()
                            .fill(AppColors.statusColor(for: s))
                            .frame(width: 8, height: 8)
                        Text(s.rawValue)
                    }
                    .tag(s)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()

            Toggle(isOn: $hasDeadline) {
                FieldLabel("Deadline")
            }
            if hasDeadline {
                DatePicker("", selection: Binding(
                    get: { deadline ?? Date() },
                    set: { deadline = $0 }
                ), displayedComponents: .date)
                .datePickerStyle(.field)
                .labelsHidden()
            }
        }
    }

    private var workTrackingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.fieldGap) {
            SectionHeader("Work Tracking")

            if let paper = existingPaper {
                HStack {
                    Text("Total time")
                        .font(AppTypography.bodySecondary)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(DateFormatting.formatTimer(paper.totalSeconds))
                        .font(AppTypography.timerText)
                        .foregroundColor(AppColors.accentPrimary)
                }
                if paper.isRunning {
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(AppColors.accentPrimary)
                        Text("Currently running")
                            .font(AppTypography.metaLabel)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            } else {
                Text("Work tracking starts after the paper is created.")
                    .font(AppTypography.bodySecondary)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.fieldGap) {
            SectionHeader("Notes")
            TextEditor(text: $note)
                .font(AppTypography.bodyPrimary)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.control)
                        .stroke(AppColors.lineSubtle, lineWidth: 1)
                )
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if !isNew {
                Button("Delete", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .font(AppTypography.buttonLabel)
            }
            Spacer()
            Button("Cancel") { tryDismiss() }
                .font(AppTypography.buttonLabel)
                .keyboardShortcut(.escape, modifiers: [])
            PrimaryButton(title: "Save", action: save)
        }
        .padding(.horizontal, AppSpacing.sheetPadding)
        .padding(.vertical, AppSpacing.space8)
        // Dirty state alert
        .alert("Discard Changes?", isPresented: $showDirtyAlert) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes.")
        }
        // Delete confirmation
        .alert("Delete Paper", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { deletePaper() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("删除「\(existingPaper?.title ?? "")」后将不可撤销。关联的日志也会保留。")
        }
    }

    // MARK: - Actions

    private func save() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "标题不能为空"
            return
        }
        validationError = nil

        let now = Date()
        if let paper = existingPaper {
            // Update existing
            var papers = dataStore.appData.papers
            if let idx = papers.firstIndex(where: { $0.id == paper.id }) {
                papers[idx].title = title
                papers[idx].journal = journal
                papers[idx].status = status
                papers[idx].deadline = hasDeadline ? deadline : nil
                papers[idx].note = note
                papers[idx].updatedAt = now
            }
            dataStore.appData.papers = papers
        } else {
            // Create new
            let newPaper = Paper(
                id: UUID().uuidString,
                title: title,
                status: status,
                journal: journal,
                deadline: hasDeadline ? deadline : nil,
                totalSeconds: 0,
                isRunning: false,
                sessionStart: nil,
                createdAt: now,
                updatedAt: now,
                note: note
            )
            dataStore.appData.papers.append(newPaper)
        }

        if dataStore.saveOrReportError() {
            dismiss()
        }
    }

    private func deletePaper() {
        guard let paper = existingPaper else { return }
        dataStore.appData.papers.removeAll { $0.id == paper.id }
        if dataStore.saveOrReportError() {
            dismiss()
        }
    }

    private func tryDismiss() {
        if isDirty {
            showDirtyAlert = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Reusable form helpers

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(AppTypography.sectionTitle)
            .foregroundColor(AppColors.textPrimary)
    }
}

private struct FieldLabel: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(AppTypography.fieldLabel)
            .foregroundColor(AppColors.textSecondary)
    }
}

#Preview {
    @Previewable @StateObject var env = AppEnvironment.bootstrap()
    return PaperEditorSheet(dataStore: env.dataStore)
}
