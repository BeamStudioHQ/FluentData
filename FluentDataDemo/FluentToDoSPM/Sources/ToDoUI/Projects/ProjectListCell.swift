import SwiftUI
import ToDoCore

struct ProjectListCell: View {
    var item: ProjectModel

    var body: some View {
        NavigationLink(value: item) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: item.name)
                    .fontWeight(.bold)

                Text(verbatim: item.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}
