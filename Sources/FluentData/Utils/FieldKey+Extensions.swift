public extension FieldKey {
    /// Easily generate the complete field key for a group field
    /// - Parameter field: Field key of inner field
    /// - Returns: A new field key matching Fluent's expectations
    func group(field: FieldKey) -> FieldKey {
        return FieldKey(stringLiteral: "\(description)_\(field.description)")
    }
}
