import FluentKit
import Foundation

/// A registry for ``FluentDataContext`` instances
public enum FluentDataContexts {
    private static var contexts: [ObjectIdentifier: FluentDataContext] = [:]
    private static var defaultId: ObjectIdentifier?

    /// Returns the default context, if any. Default context can be specified in ``FluentDataContext``'s initializer.
    public static var `default`: FluentDataContext? {
        guard let defaultId else { return nil }
        return contexts[defaultId]
    }

    public internal(set) static subscript<K>(key: K.Type, makeDefault: Bool? = nil) -> FluentDataContext where K: FluentDataContextKey {
        get {
            guard let context = contexts[ObjectIdentifier(key.self)] else {
                fatalError("FluentData context not found for key `\(key)`. Make sure to instantiate context beforehand.")
            }
            return context
        }
        set {
            contexts[ObjectIdentifier(key.self)] = newValue

            if (defaultId == nil && makeDefault == nil) || makeDefault == true {
                defaultId = ObjectIdentifier(key.self)
            }
        }
    }
}
