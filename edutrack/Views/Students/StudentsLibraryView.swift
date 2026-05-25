import SwiftUI

struct StudentsLibraryView: View {
    @StateObject private var viewModel = StudentsViewModel()
    @State private var showingCreateStudent = false

    var body: some View {
        Group {
            if viewModel.students.isEmpty && viewModel.searchText.isEmpty {
                EmptyStateView(icon: "person.3", title: "No Students", message: "Tap + to register students.")
            } else {
                List {
                    ForEach(viewModel.filtered) { student in
                        VStack(alignment: .leading) {
                            Text(student.fullName).font(.headline)
                            Text(student.email).font(.subheadline).foregroundColor(AppColors.textSecondary)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                // Add logic for AddStudentToSectionSheet
                            } label: {
                                Label("Add to Class", systemImage: "plus.circle")
                            }
                            .tint(AppColors.primary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Students Library")
        .searchable(text: $viewModel.searchText)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateStudent = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateStudent) {
            CreateStudentSheet(viewModel: viewModel)
        }
        .background(AppColors.background.ignoresSafeArea())
    }
}

struct CreateStudentSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: StudentsViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var studentNumber = ""
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Student ID", text: $studentNumber)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .navigationTitle("New Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.createStudent(
                                firstName: firstName,
                                lastName: lastName,
                                studentNumber: studentNumber,
                                email: email
                            )
                            dismiss()
                        }
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty || studentNumber.isEmpty || email.isEmpty)
                }
            }
        }
    }
}
