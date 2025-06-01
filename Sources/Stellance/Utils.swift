

extension Array {
    @inlinable func anySatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        for elem in self {
            if try predicate(elem) {
                return true
            }
        }
        return false
    }
}
