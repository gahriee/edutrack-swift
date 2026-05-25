import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingAddClass = false

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.classes.isEmpty {
                EmptyStateView(icon: "book.closed", title: "No Classes", message: "Tap + to add your first class.")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.classes) { schoolClass in
                            NavigationLink(value: schoolClass) {
                                ClassCardView(schoolClass: schoolClass)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteClass(schoolClass) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddClass = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddClass) {
            AddClassSheet(viewModel: viewModel)
        }
        .navigationDestination(for: SchoolClass.self) { schoolClass in
            ClassDetailView(schoolClass: schoolClass)
        }
        .background(AppColors.background.ignoresSafeArea())
    }
}

struct ClassCardView: View {
    let schoolClass: SchoolClass

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(schoolClass.name)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
            Text(schoolClass.subject)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AddClassSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DashboardViewModel
    @State private var name = ""
    @State private var subject = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Class Name", text: $name)
                TextField("Subject", text: $subject)
            }
            .navigationTitle("New Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addClass(name: name, subject: subject)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || subject.isEmpty)
                }
            }
        }
    }
}
