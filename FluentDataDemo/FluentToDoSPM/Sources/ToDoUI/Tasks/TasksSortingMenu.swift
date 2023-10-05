import SwiftUI
import ToDoCore

struct TasksSortingMenu: View {
    @Binding private var sortCriteria: TaskModel.SortCriteria
    @Binding private var sortDirection: SortDirection

    init(sortCriteria: Binding<TaskModel.SortCriteria>, sortDirection: Binding<SortDirection>) {
        self._sortCriteria = sortCriteria
        self._sortDirection = sortDirection
    }

    var body: some View {
        Menu {
            Picker(selection: $sortCriteria) {
                Text(verbatim: "Name")
                    .tag(TaskModel.SortCriteria.name)

                Text(verbatim: "Status")
                    .tag(TaskModel.SortCriteria.done)

                Text(verbatim: "Creation date")
                    .tag(TaskModel.SortCriteria.createdAt)

                Text(verbatim: "Last modification date")
                    .tag(TaskModel.SortCriteria.updatedAt)
            } label: {
                Text(verbatim: "Sort by")
            }

            Picker(selection: $sortDirection) {
                Text(verbatim: "Ascending")
                    .tag(SortDirection.ascending)

                Text(verbatim: "Descending")
                    .tag(SortDirection.descending)
            } label: {
                Text(verbatim: "Sort by")
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down.square")
                .labelStyle(.iconOnly)
        }
    }
}
