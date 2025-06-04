import Stella

infix operator ~>: BitwiseShiftPrecedence

func +(context: Context, bind: Binding) throws -> Context {
    let pattern = bind.pattern
    let type = bind.type
    let badPattern = Code.error(.unexpectedPattern(pattern, for: type))

    switch pattern {
    case let .var(name):
        return context + name ~> type

    case .false, .true, .unit, .int:
        return context

    case let .succ(inner):
        guard case .nat = type else {
            throw badPattern
        }
        return try context + inner ~> .nat

    case let .tuple(patterns):
        guard case let .tuple(types) = type, types.count == patterns.count else {
            throw badPattern
        }
        return try zip(patterns, types).map(~>).reduce(context, +)

    case let .record(fieldPatterns):
        guard case let .record(fieldTypes) = type,
              Set(fieldPatterns.map(\.0)) == Set(fieldTypes.map(\.0))
        else {
            throw badPattern
        }
        let typeForField = Dictionary(uniqueKeysWithValues: fieldTypes)
        let bindings = fieldPatterns.map { (field, pattern) in
            pattern ~> typeForField[field]!
        }
        return try bindings.reduce(context, +)

    case let .inl(inner):
        guard case let .sum(left, _) = type else {
            throw badPattern
        }
        return try context + inner ~> left

    case let .inr(inner):
        guard case let .sum(_, right) = type else {
            throw badPattern
        }
        return try context + inner ~> right

    case let .list(patterns):
        guard case let .list(of) = type else {
            throw badPattern
        }
        return try patterns.map { $0 ~> of }.reduce(context, +)

    case let .cons(head, tail):
        guard case let .list(of) = type else {
            throw badPattern
        }
        return try context + head ~> of + tail ~> .list(of: of)

    case let .variant(name, forPattern):
        guard case let .variant(tags) = type else {
            throw badPattern
        }
        guard let (_, tagType) = tags.first(where: { $0.0 == name }) else {
            throw badPattern
        }
        if let tagType {
            guard let forPattern else {
                throw Code.error(
                    .unexpectedNullVariantPattern(
                        for: name, missedType: tagType, in: pattern, type: type
                    )
                )
            }
            return try context + forPattern ~> tagType
        }
        guard forPattern == nil else {
            throw Code.error(
                .unexpectedNonNullVariantPattern(for: name, in: pattern, type: type)
            )
        }
        return context

    case let .ascription(pattern, asType):
        // for future stages should be more sophisticated
        guard asType == type else {
            throw badPattern
        }
        return try context + pattern ~> asType

    default:
        throw Code.unsupported(pattern, description: "Not implemented")
    }
}

func +(context: Context, pattern: Pattern) throws -> Context {
    switch pattern {
    case .succ(let inner), .inl(let inner), .inr(let inner):
        try context + inner

    case let .tuple(patterns):
        try patterns.reduce(context, +)

    case let .record(fieldPatterns):
        try fieldPatterns.map(\.1).reduce(context, +)

    case let .list(patterns):
        try patterns.reduce(context, +)

    case let .cons(head, tail):
        try context + head + tail

    case let .variant(_, .some(pattern)):
        try context + pattern

    case let .ascription(pattern, type):
        try context + pattern ~> type

    default:
        throw Code.error(.ambiguosPattern(pattern))
    }
}
