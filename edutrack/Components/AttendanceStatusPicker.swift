import SwiftUI

extension AttendanceStatus {
    var color: Color {
        switch self {
        case .present: return AppColors.present
        case .absent:  return AppColors.absent
        case .late:    return AppColors.late
        }
    }

    var icon: String {
        switch self {
        case .present: return "checkmark.circle.fill"
        case .absent:  return "xmark.circle.fill"
        case .late:    return "clock.fill"
        }
    }
}

struct AttendanceStatusPicker: View {
    @Binding var status: AttendanceStatus

    var body: some View {
        Picker("Status", selection: $status) {
            ForEach(AttendanceStatus.allCases, id: \.self) { s in
                Text(s.label).tag(s)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}
