import SwiftUI

struct ClassDetailView: View {
    @StateObject private var viewModel: ClassDetailViewModel
    @State private var showingAddSection = false
    let schoolClass: SchoolClass

    init(schoolClass: SchoolClass) {
        self.schoolClass = schoolClass
        self._viewModel = StateObject(wrappedValue: ClassDetailViewModel(classId: schoolClass.id))
    }

    var body: some View {
        Group {
            if viewModel.sections.isEmpty {
                EmptyStateView(icon: "list.bullet.rectangle", title: "No Sections", message: "Tap + to add a section.")
            } else {
                List {
                    ForEach(viewModel.sections) { section in
                        NavigationLink(value: section) {
                            Text(section.name)
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let section = viewModel.sections[index]
                            Task { await viewModel.deleteSection(section) }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(schoolClass.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSection = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSection) {
            AddSectionSheet(viewModel: viewModel)
        }
        .navigationDestination(for: Section.self) { section in
            SectionDetailView(section: section)
        }
        .background(AppColors.background.ignoresSafeArea())
    }
}

struct AddSectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ClassDetailViewModel
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Section Name", text: $name)
            }
            .navigationTitle("New Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addSection(name: name)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
