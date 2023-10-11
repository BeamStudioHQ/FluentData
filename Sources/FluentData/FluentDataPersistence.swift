import Foundation

/// Specify the storage mediums of a context
public enum FluentDataPersistence {
    /// ``bundle(_:name:)`` provide a read-only database using the SQLite format from a bundle file.
    case bundle(_ bundle: Bundle, name: String)

    /// ``file(_:)`` will persist data on disk using the SQLite format.
    /// The file will be located in the "Application Support" folder of the currently running application.
    case file(_ name: String)

    /// ``iCloud(container:_:)`` will persist data in the specified iCloud Documents container.
    case iCloud(container: String, _ name: String)

    /// ``memory`` won't persist data across two launches of your app. This can be quite useful during the development process.
    case memory
}
