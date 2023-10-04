/// Injects a FluentContext instance
@propertyWrapper public struct WithFluentContext {
    /// Injects the default context, if any, otherwise crashes the process
    public init() {
        guard let context = FluentDataContexts.default else {
            fatalError("FluentData has no default context")
        }
        self.context = context
    }
    
    /// Injects the context matching the given key. Context needs to have been created beforehand.
    /// - Parameter contextKey: the key which uniquely identify this context
    public init<K: FluentDataContextKey>(contextKey: K.Type) {
        self.context = FluentDataContexts[contextKey]
    }
    
    let context: FluentDataContext
    
    public var wrappedValue: FluentDataContext {
        get { context }
    }
}
