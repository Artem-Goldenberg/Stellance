import Stella

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

extension Array where Element: Hashable {
    var allDuplicates: [Element] {
        Array(
            reduce(into: [:]) { dict, name in
                dict[name] = (dict[name] ?? 0) + 1
            }
            .filter { $0.value > 1 }
            .keys
        )
    }
}

extension DefaultStringInterpolation {
    private static let maxLineWidth = 80

    mutating func appendInterpolation(wrap value: String) {
        let taken = String(stringInterpolation: self)
            .reversed()
            .prefix { $0 != "\n" }
            .count

        let left = Self.maxLineWidth - taken

        if value.count < left {
            appendInterpolation(value)
        } else {
            appendLiteral("\n    ")
            appendInterpolation(indented: value)
        }
    }

    // This extension is a life saver!!!
    // got it from: https://forums.swift.org/t/multi-line-string-nested-indentation-with-interpolation/36933
    mutating func appendInterpolation(indented string: String) {
        let indent = String(stringInterpolation: self)
            .reversed()
            .prefix {" \t".contains($0)}
        if indent.isEmpty {
            appendInterpolation(string)
        } else {
            appendLiteral(
                string.split(
                    separator: "\n",
                    omittingEmptySubsequences: false
                ).joined(separator: "\n" + indent)
            )
        }
    }

    mutating func appendInterpolation(enum names: [Identifier]) {
        appendLiteral(names.map(\.code).joined(separator: ", "))
    }
}

extension String {
    init(byDumping stuff: Any) {
        var str = String()
        dump(stuff, to: &str)
        self = str
    }
}
