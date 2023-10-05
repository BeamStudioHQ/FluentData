import SwiftUI
import ToDoCore

struct ProjectListCell: View {
    var item: ProjectModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(verbatim: item.name)
                .font(.title3.bold())

            Text(verbatim: item.description)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
