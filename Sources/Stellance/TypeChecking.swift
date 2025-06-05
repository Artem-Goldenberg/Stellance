import Stella

infix operator ~>: BitwiseShiftPrecedence

func |-(context: Context, check: TypeCheck) throws {
    let type = check.type
    let expr = check.node

    if case .top = type {
        // otherwise, we would be here till the morning, oh, wait...
        let _ = try context |- expr
        return
    }

    switch check.node {
    case let .if(condition, onTrue, onFalse):
        try context |- condition <= .bool
        try context |- onTrue <= type
        try context |- onFalse <= type

    case let .natRec(numExpr, iniExpr, stepExpr):
        try context |- numExpr <= .nat
        try context |- iniExpr <= type
        try context |- stepExpr <= .function(
            from: [.nat],
            to: .function(from: [type], to: type)
        )

    case let .abstraction(parameters, body):
        guard case let .function(paramTypes, returnType) = type else {
            throw Code.error(.unexpectedLambda(expr, expected: type))
        }
        guard paramTypes.count == parameters.count else {
            throw Code.error(
                .unexpectedParametersNumber(
                    parameters.count, expected: paramTypes.count,
                    for: type, in: expr
                )
            )
        }
        for (param, expectedType) in zip(parameters, paramTypes) {
            guard compare(expectedType, param.type, in: context) else {
                throw Code.error(
                    .unexpectedParameterType(
                        param.type, expected: expectedType,
                        for: param.name, calleeType: type, in: expr
                    )
                )
            }
        }
        // this is sick!!!
        try parameters.reduce(context, +) |- body <= returnType

    case let .tuple(elems):
        guard case let .tuple(types) = type else {
            throw Code.error(.unexpectedTuple(expr, expected: type))
        }
        guard types.count == elems.count else {
            throw Code.error(
                .unexpectedLength(
                    elems.count, expected: types.count, for: type, in: expr
                )
            )
        }
        for (elem, type) in zip(elems, types) {
            try context |- elem <= type
        }

    case let .record(fields):
        guard case let .record(fieldTypes) = type else {
            throw Code.error(.unexpectedRecord(expr, expected: type))
        }
        let fieldNames = Set(fields.map(\.0))
        let expectedFieldNames = Set(fieldTypes.map(\.0))

        let extraFields = fieldNames.subtracting(expectedFieldNames)
        let missingFields = expectedFieldNames.subtracting(fieldNames)

        guard missingFields.isEmpty else {
            throw Code.error(.missingFields(.init(missingFields), for: type, in: expr))
        }
        guard extraFields.isEmpty || context.isEnabled(.subtyping) else {
            throw Code.error(.unexpectedFields(.init(extraFields), for: type, in: expr))
        }

        // now we confirmed keys are all the same or it's a subtype!
        let typeForField = Dictionary(uniqueKeysWithValues: fieldTypes)
        for (field, expr) in fields {
            if let type = typeForField[field] {
                try context |- expr <= type
            } else {
                let _ = try context |- expr
            }
        }

    case let .let(bindings, inExpr):
        try bindings.reduce(context) { context, bind in
            try context + bind.0 ~> (context |- bind.1)
        } |- inExpr <= type

    case let .letrec(bindings, inExpr):
        try bindings.reduce(context) { context, bind in
            let (pattern, expr) = bind
            let enriched = try context + pattern
            return try context + pattern ~> (enriched |- expr)
        } |- inExpr <= type

    case let .inl(inner):
        guard case let .sum(left, _) = type else {
            throw Code.error(.unexpectedInjection(expr, expected: type))
        }
        try context |- inner <= left

    case let .inr(inner):
        guard case let .sum(_, right) = type else {
            throw Code.error(.unexpectedInjection(expr, expected: type))
        }
        try context |- inner <= right

    case let .match(matchee, branches):
        // exhaustiveness check
        let matchingType = try context |- matchee
        for (pattern, expr) in branches {
            try context + pattern ~> matchingType |- expr <= type
        }
        guard branches.map(\.0) |? matchingType else {
            throw Code.error(.nonexhaustiveMatch(expr, for: matchingType))
        }

    case let .list(elems):
        guard case let .list(of) = type else {
            throw Code.error(.unexpectedList(expr, expected: type))
        }
        try elems.forEach { try context |- $0 <= of }

    case let .consList(head, tail):
        guard case let .list(of) = type else {
            throw Code.error(.unexpectedList(expr, expected: type))
        }
        try context |- head <= of
        try context |- tail <= .list(of: of)

    case let .variant(name, forExpr):
        guard case let .variant(tags) = type else {
            throw Code.error(.unexpectedVariant(expr, expected: type))
        }
        guard let (_, tagType) = tags.first(where: { $0.0 == name }) else {
            throw Code.error(.unexpectedTag(name, for: type, in: expr))
        }
        if let tagType {
            guard let forExpr else {
                throw Code.error(
                    .missingData(for: name, of: tagType, in: expr, expected: type)
                )
            }
            try context |- forExpr <= tagType
        } else {
            guard forExpr == nil else {
                throw Code.error(.unexpectedData(for: name, in: expr, expected: type))
            }
        }

//    case let .fix(fixee): could be inferring but then error message will be wrong
//        try context |- fixee <= .function(from: [type], to: type)

    case let .sequence(first, second):
        try context |- first <= .unit
        try context |- second <= type

    case let .ref(toExpr):
        guard case .reference(let toType) = type else {
            throw Code.error(.unexpectedReference(toExpr, expected: type))
        }
        try context |- toExpr <= toType

    case let .deref(ref):
        try context |- ref <= .reference(type)

    case .constMemory:
        guard case .reference(_) = type else {
            throw Code.error(.unexpectedAddress(expr, expected: type))
        }
        // we just say ok ???? What is this even about?
        return

    case .panic:
        return

    case let .throw(theExpr):
        guard let throwType = context.exceptionType else {
            throw Code.error(.exceptionNotDeclared(usedIn: expr))
        }
        try context |- theExpr <= throwType

    case let .tryWith(expr, recover):
        try context |- expr <= type
        try context |- recover <= type

    case let .tryCatch(tryExpr, pattern, recover):
        try context |- tryExpr <= type
        guard let throwType = context.exceptionType else {
            throw Code.error(.exceptionNotDeclared(usedIn: expr))
        }
        try context + pattern ~> throwType |- recover <= type

    case let .tryCastAs(tryExpr, type, pattern, newExpr, with: recover):
        let _ = try context |- tryExpr
        try context + pattern ~> type |- newExpr <= type
        try context |- recover <= type

    default:
        // try infering type instead
        let inferred = try context |- expr
        if !context.isEnabled(.subtyping) {
            guard inferred == type else {
                throw Code.error(.unexpectedType(inferred, expected: type, in: expr))
            }
            return
        }
        guard inferred ~ type else {
            throw Code.error(.unexpectedSubtype(inferred, of: type, in: expr))
        }
    }
}

func compare(_ type1: Type, _ type2: Type, in context: Context) -> Bool {
    if context.isEnabled(.subtyping) {
        return type1 ~ type2
    } else {
        return type1 == type2
    }
}

infix operator |?: MultiplicationPrecedence

// not ideal, a lot of potential to improve
func |?(patterns: [Pattern], type: Type) -> Bool {
    if patterns.contains(where: {
        if case .var = $0 {
            return true
        }
        return false
    }) {
        return true
    }

    switch type {
    case .bool:
        return patterns.contains(.true) && patterns.contains(.false)
    case .nat:
        return patterns.contains(.int(0))
        && patterns.contains {
            if case .succ = $0 { return true }
            return false
        }
    case .sum:
        return patterns.contains {
            if case .inl = $0 {
                return true
            }
            return false
        } &&
        patterns.contains {
            if case .inr = $0 {
                return true
            }
            return false
        }
    case .list:
        return patterns.contains {
            if case .list([]) = $0 {
                return true
            }
            return false
        } &&
        patterns.contains {
            if case .cons = $0 {
                return true
            }
            return false
        }
    case .variant(let tags):
        return tags.reduce(true) { result, tag in
            let (name, type) = tag
            return result && patterns.contains {
                guard case let .variant(tag, pattern) = $0, tag == name else {
                    return false
                }
                switch (pattern, type) {
                case (.some, .some):
                    return true
                case (.none, .none):
                    return true
                default:
                    return false
                }
            }
        }
    default: return true
    }
}
