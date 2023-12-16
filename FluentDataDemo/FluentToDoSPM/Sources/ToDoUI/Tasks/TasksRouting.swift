import Foundation
import ToDoCore

struct TasksRouting {
    var showCreationSheet: CreationSheet? = nil
}

extension TasksRouting {
    enum CreationSheet: Identifiable {
        case `default`
        case withProject(ProjectModel)

        static let defaultIdentifier: NSObject = NSObject()

        var id: ObjectIdentifier {
            switch self {
            case .default:
                return ObjectIdentifier(Self.defaultIdentifier)
            case .withProject(let project):
                return ObjectIdentifier(project)
            }
        }
    }
}
