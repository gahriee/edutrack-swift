import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingAddClass = false

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColors.primary)
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.classes.isEmpty {
                    EmptyStateView(
                        icon: "books.vertical.fill", 
                        title: "No Classes", 
                        message: "Tap + to add your first class."
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.classes) { schoolClass in
                                NavigationLink(value: schoolClass) {
                                    ClassCardView(schoolClass: schoolClass)
                                }
                                .buttonStyle(PlainButtonStyle())
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
                        .padding(.bottom, 80) // Prevents FAB from overlapping last row
                    }
                }
            }
            
            if !viewModel.isLoading {
                Button {
                    showingAddClass = true
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
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddClass) {
            AddClassSheet(viewModel: viewModel)
        }
        .navigationDestination(for: SchoolClass.self) { schoolClass in
            ClassDetailView(schoolClass: schoolClass)
        }
        .background(AppColors.background.ignoresSafeArea())
    }
}

fileprivate struct ClassCardView: View {
    let schoolClass: SchoolClass

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [AppColors.primary, AppColors.secondary], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "book.fill")
                    .foregroundColor(AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(schoolClass.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    
                Text(schoolClass.subject)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 16)
            
            HStack {
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(AppColors.primary.opacity(0.8))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

struct AddClassSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DashboardViewModel
    @State private var name = ""
    @State private var subject = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header Graphic
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "plus.rectangle.on.folder.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }
                .padding(.top, 32)
                
                VStack(spacing: 8) {
                    Text("Create New Class")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.textPrimary)
                    Text("Set up a new class to manage attendance.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(spacing: 16) {
                    AuthTextField(title: "Class Name (e.g. Mathematics 101)", text: $name)
                    AuthTextField(title: "Subject (e.g. Math)", text: $subject)
                    
                    Button(action: {
                        Task {
                            await viewModel.addClass(name: name, subject: subject)
                            dismiss()
                        }
                    }) {
                        Text("Create Class")
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity((name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1)
                }
                .padding(.horizontal)
                
                Spacer()
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
