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
            // Date Bar
            HStack {
                Button {
                    let prevDay = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate)!
                    viewModel.changeDate(to: prevDay)
                } label: {
                    Image(systemName: "chevron.left")
                        .padding()
                }

                DatePicker("", selection: Binding(
                    get: { viewModel.selectedDate },
                    set: { viewModel.changeDate(to: $0) }
                ), displayedComponents: .date)
                .labelsHidden()

                Button {
                    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate)!
                    viewModel.changeDate(to: nextDay)
                } label: {
                    Image(systemName: "chevron.right")
                        .padding()
                }
            }
            .padding(.vertical, 8)
            .background(AppColors.surface)

            // Summary Badges
            let counts = getCounts()
            HStack(spacing: 16) {
                BadgeView(title: "Present", count: counts.present, color: AppColors.present)
                BadgeView(title: "Absent", count: counts.absent, color: AppColors.absent)
                BadgeView(title: "Late", count: counts.late, color: AppColors.late)
            }
            .padding()
            .background(AppColors.surface)
            .padding(.bottom, 8)

            // Student List
            if viewModel.students.isEmpty {
                EmptyStateView(icon: "person.crop.circle.badge.plus", title: "No Students", message: "Add students from the library.")
            } else {
                List {
                    ForEach(viewModel.students) { student in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(student.fullName)
                                    .font(.headline)
                                Text(student.studentNumber)
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            AttendanceStatusPicker(status: Binding(
                                get: { viewModel.statusForStudent(student) },
                                set: { newStatus in
                                    Task { await viewModel.updateStatus(for: student, status: newStatus) }
                                }
                            ))
                            .frame(width: 150)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let student = viewModel.students[index]
                            Task { await viewModel.removeStudentFromSection(student) }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(section.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ShareLink(item: viewModel.exportCSV()) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
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

struct BadgeView: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
