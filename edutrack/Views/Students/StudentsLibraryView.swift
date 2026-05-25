import SwiftUI

struct StudentsLibraryView: View {
    @StateObject private var viewModel = StudentsViewModel()
    @State private var showingCreateStudent = false
    @State private var studentToEdit: Student?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if viewModel.students.isEmpty && viewModel.searchText.isEmpty {
                    EmptyStateView(
                        icon: "person.3.fill", 
                        title: "No Students", 
                        message: "Tap + to register students to your library."
                    )
                } else {
                    List {
                        ForEach(viewModel.filtered) { student in
                            StudentLibraryCard(student: student)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.deleteStudent(student) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        studentToEdit = student
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        // Add logic for AddStudentToSectionSheet
                                    } label: {
                                        Label("Add to Class", systemImage: "folder.badge.plus")
                                    }
                                    .tint(AppColors.primary)
                                }
                        }
                        
                        // Add transparent padding so FAB doesn't obscure the last item
                        Color.clear
                            .frame(height: 80)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.top, 8)
                }
            }
            
            Button {
                showingCreateStudent = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(colors: [AppColors.primary, AppColors.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .shadow(color: AppColors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("Students Library")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText)
        .sheet(isPresented: $showingCreateStudent) {
            CreateStudentSheet(viewModel: viewModel)
        }
        .sheet(item: $studentToEdit) { student in
            EditStudentSheet(viewModel: viewModel, student: student)
        }
        .background(AppColors.background.ignoresSafeArea())
    }
}

fileprivate struct StudentLibraryCard: View {
    let student: Student
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 48, height: 48)
                Text(String(student.firstName.prefix(1) + student.lastName.prefix(1)).uppercased())
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(student.fullName)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text(student.email)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("ID")
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
                Text(student.studentNumber)
                    .font(.caption.bold())
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Graphic
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                    .padding(.top, 32)
                    
                    VStack(spacing: 8) {
                        Text("Register Student")
                            .font(.title2.bold())
                            .foregroundColor(AppColors.textPrimary)
                        Text("Add a new student to your library.")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    VStack(spacing: 16) {
                        AuthTextField(title: "First Name", text: $firstName)
                        AuthTextField(title: "Last Name", text: $lastName)
                        AuthTextField(title: "Student ID (e.g. 20230001)", text: $studentNumber)
                        AuthTextField(title: "Email", text: $email)
                        
                        Button(action: {
                            Task {
                                await viewModel.createStudent(
                                    firstName: firstName,
                                    lastName: lastName,
                                    studentNumber: studentNumber,
                                    email: email
                                )
                                dismiss()
                            }
                        }) {
                            Text("Register Student")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [AppColors.primary, AppColors.secondary], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: AppColors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .padding(.top, 8)
                        .disabled(firstName.isEmpty || lastName.isEmpty || studentNumber.isEmpty || email.isEmpty)
                        .opacity((firstName.isEmpty || lastName.isEmpty || studentNumber.isEmpty || email.isEmpty) ? 0.6 : 1)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}

struct EditStudentSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: StudentsViewModel
    let student: Student
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var studentNumber: String
    @State private var email: String

    init(viewModel: StudentsViewModel, student: Student) {
        self.viewModel = viewModel
        self.student = student
        _firstName = State(initialValue: student.firstName)
        _lastName = State(initialValue: student.lastName)
        _studentNumber = State(initialValue: student.studentNumber)
        _email = State(initialValue: student.email)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Graphic
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                    .padding(.top, 32)
                    
                    VStack(spacing: 8) {
                        Text("Edit Student")
                            .font(.title2.bold())
                            .foregroundColor(AppColors.textPrimary)
                        Text("Update the student's information.")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    VStack(spacing: 16) {
                        AuthTextField(title: "First Name", text: $firstName)
                        AuthTextField(title: "Last Name", text: $lastName)
                        AuthTextField(title: "Student ID (e.g. 20230001)", text: $studentNumber)
                        AuthTextField(title: "Email", text: $email)
                        
                        Button(action: {
                            Task {
                                await viewModel.updateStudent(
                                    student,
                                    firstName: firstName,
                                    lastName: lastName,
                                    studentNumber: studentNumber,
                                    email: email
                                )
                                dismiss()
                            }
                        }) {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [AppColors.primary, AppColors.secondary], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: AppColors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .padding(.top, 8)
                        .disabled(firstName.isEmpty || lastName.isEmpty || studentNumber.isEmpty || email.isEmpty)
                        .opacity((firstName.isEmpty || lastName.isEmpty || studentNumber.isEmpty || email.isEmpty) ? 0.6 : 1)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}
