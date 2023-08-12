@propertyWrapper public struct WithFluentContext {
    public init() {
        guard let context = FluentDataContexts.default else {
            fatalError("FluentData has no default context")
        }
        self.context = context
    }
    
    public init<K: FluentDataContextKey>(contextKey: K.Type) {
        self.context = FluentDataContexts[contextKey]
    }
    
    let context: FluentDataContext
    
    public var wrappedValue: FluentDataContext {
        get { context }
    }
}
