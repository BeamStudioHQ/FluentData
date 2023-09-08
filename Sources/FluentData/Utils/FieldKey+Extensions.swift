public extension FieldKey {
    func group(field: FieldKey) -> FieldKey {
        return FieldKey(stringLiteral: "\(description)_\(field.description)")
    }
}
