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
        ZStack(alignment: .bottomTrailing) {
            Group {
                if viewModel.sections.isEmpty {
                    EmptyStateView(
                        icon: "rectangle.3.group", 
                        title: "No Sections", 
                        message: "Tap + to add a section for this class."
                    )
                } else {
                    List {
                        ForEach(viewModel.sections) { section in
                            ZStack {
                                SectionCardView(section: section)
                                NavigationLink(value: section) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let section = viewModel.sections[index]
                                Task { await viewModel.deleteSection(section) }
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
                showingAddSection = true
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
        .navigationTitle(schoolClass.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddSection) {
            AddSectionSheet(viewModel: viewModel)
        }
        .navigationDestination(for: Section.self) { section in
            SectionDetailView(section: section)
        }
        .background(AppColors.background.ignoresSafeArea())
    }
}

fileprivate struct SectionCardView: View {
    let section: Section
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [AppColors.primary, AppColors.secondary], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "rectangle.3.group.fill")
                    .foregroundColor(AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(section.name)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(section.studentIds.count) Student\(section.studentIds.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.outline)
                .font(.footnote.weight(.semibold))
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

struct AddSectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ClassDetailViewModel
    @State private var name = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header Graphic
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "rectangle.badge.plus")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }
                .padding(.top, 32)
                
                VStack(spacing: 8) {
                    Text("Add a Section")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.textPrimary)
                    Text("Organize your class into manageable groups.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(spacing: 16) {
                    AuthTextField(title: "Section Name (e.g. Lab A)", text: $name)
                    
                    Button(action: {
                        Task {
                            await viewModel.addSection(name: name)
                            dismiss()
                        }
                    }) {
                        Text("Create Section")
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
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
