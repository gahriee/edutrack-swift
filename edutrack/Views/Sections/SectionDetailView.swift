import SwiftUI

struct SectionDetailView: View {
    @StateObject private var viewModel: SectionDetailViewModel
    let section: Section

    init(section: Section) {
        self.section = section
        self._viewModel = StateObject(wrappedValue: SectionDetailViewModel(section: section))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Date Bar
            HStack {
                Button {
                    let prevDay = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate)!
                    withAnimation { viewModel.changeDate(to: prevDay) }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.primary)
                }
                
                Spacer()

                DatePicker("", selection: Binding(
                    get: { viewModel.selectedDate },
                    set: { viewModel.changeDate(to: $0) }
                ), displayedComponents: .date)
                .labelsHidden()
                
                Spacer()
                
                Button {
                    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate)!
                    withAnimation { viewModel.changeDate(to: nextDay) }
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(AppColors.surface)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
            .padding(.top, 16)
            .zIndex(1) // Keep shadow over content

            // Summary Badges
            let counts = getCounts()
            HStack(spacing: 12) {
                BadgeView(title: "Present", count: counts.present, color: AppColors.present, icon: "checkmark.circle.fill")
                BadgeView(title: "Absent", count: counts.absent, color: AppColors.absent, icon: "xmark.circle.fill")
                BadgeView(title: "Late", count: counts.late, color: AppColors.late, icon: "clock.fill")
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Student List
            if viewModel.students.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "person.crop.circle.badge.plus", 
                    title: "No Students Yet", 
                    message: "Add students from the library to start tracking attendance."
                )
                Spacer()
            } else {
                List {
                    ForEach(viewModel.students) { student in
                        StudentRowCard(student: student, viewModel: viewModel)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let student = viewModel.students[index]
                            Task { await viewModel.removeStudentFromSection(student) }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(section.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ShareLink(item: viewModel.exportCSV()) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundColor(AppColors.primary)
                        .font(.title3)
                }
            }
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    private func getCounts() -> (present: Int, absent: Int, late: Int) {
        var present = 0
        var absent = 0
        var late = 0
        for student in viewModel.students {
            switch viewModel.statusForStudent(student) {
            case .present: present += 1
            case .absent: absent += 1
            case .late: late += 1
            }
        }
        return (present, absent, late)
    }
}

fileprivate struct StudentRowCard: View {
    let student: Student
    @ObservedObject var viewModel: SectionDetailViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Initials Avatar
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Text(String(student.firstName.prefix(1) + student.lastName.prefix(1)).uppercased())
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundColor(AppColors.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.fullName)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text(student.studentNumber)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            Divider()
                .padding(.horizontal, -16)
            
            AttendanceStatusPicker(status: Binding(
                get: { viewModel.statusForStudent(student) },
                set: { newStatus in
                    Task { await viewModel.updateStatus(for: student, status: newStatus) }
                }
            ))
            .padding(.top, 4)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

fileprivate struct BadgeView: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
