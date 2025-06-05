import Stella

infix operator ~>: BitwiseShiftPrecedence

/// Type inference
func |-(context: Context, expr: Expression) throws -> Type {
    switch expr {
    case .var(let identifier):
        guard let type = context.type(of: identifier) else {
            throw Code.error(.undefinedVariable(identifier))
        }
        return type
    case .constTrue, .constFalse: return .bool

    case let .if(condition, onTrue, onFalse):
        try context |- condition <= .bool
        let type = try context |- onTrue
        try context |- onFalse <= type
        return type

    case .constInt(_): return .nat

    case let .application(callee, arguments):
        let calleeType = try context |- callee
        guard case let .function(paramTypes, returnType) = calleeType else {
            throw Code.error(.notAFunction(actualType: calleeType, what: callee, in: expr))
        }
        guard arguments.count == paramTypes.count else {
            throw Code.error(
                .incorrectArgumentsNumber(
                    arguments.count, expected: paramTypes.count,
                    for: calleeType, in: expr
                )
            )
        }
        for (argument, type) in zip(arguments, paramTypes) {
            try context |- argument <= type
        }
        return returnType

    case .succ(let nat):
        try context |- nat <= .nat
        return .nat
    case .isZero(let nat):
        try context |- nat <= .nat
        return .bool

    case .natRec(let num, let ini, let step):
        try context |- num <= .nat
        let type = try context |- ini
        try context |- step <= .function(from: [.nat], to: .function(from: [type], to: type))
        return type

    case let .abstraction(parameters, body):
        let returnType = try parameters.reduce(context, +) |- body
        return .function(from: parameters.map(\.type), to: returnType)

    case .constUnit: return .unit

    case let .tuple(elems):
        let types = try elems.map { try context |- $0 }
        return .tuple(types)

    case let .dotTuple(indexee, index):
        let indexeeType = try context |- indexee
        guard case let .tuple(types) = indexeeType else {
            throw Code.error(.notATuple(actualType: indexeeType, in: expr))
        }
        guard 1 <= index, index <= types.count else {
            throw Code.error(.unexpectedIndex(index, for: indexeeType, in: expr))
        }
        return types[index - 1]

    case let .record(fields):
        let types = try fields.map(\.1).map { try context |- $0 }
        return .record(.init(zip(fields.map(\.0), types)))

    case let .dotRecord(indexee, name):
        let indexeeType = try context |- indexee
        guard case let .record(fields) = indexeeType else {
            throw Code.error(.notARecord(actualType: indexeeType, in: expr))
        }
        guard let field = fields.first(where: { $0.0 == name }) else {
            throw Code.error(.unexpectedFieldAccess(name, for: indexeeType, in: expr))
        }
        return field.1

    case let .let(bindings, inExpr):
        return try bindings.reduce(context) { context, bind in
            let (pattern, expr) = bind
            let type = try context |- expr
            return try context + pattern ~> type
        } |- inExpr

    case let .letrec(bindings, inExpr):
        return try bindings.reduce(context) { context, bind in
            let (pattern, expr) = bind
            let enriched = try context + pattern
            return try context + pattern ~> (enriched |- expr)
        } |- inExpr

    case let .typeAscription(ascriptee, type):
        try context |- ascriptee <= type
        return type

    case let .inl(inner):
        let left = try context |- inner
        guard context.isEnabled(.asBottom) else {
            throw Code.error(.ambiguosSum(expr))
        }
        return .sum(left: left, right: .bottom)

    case let .inr(inner):
        let right = try context |- inner
        guard context.isEnabled(.asBottom) else {
            throw Code.error(.ambiguosSum(expr))
        }
        return .sum(left: .bottom, right: right)

    case let .match(matchee, branches):
        let matchingType = try context |- matchee
        guard let (pattern, inExpr) = branches.first else {
            // cannot really happen as this is syntax checked
            throw Code.error(.emptyMatch(expr))
        }
        // infer first type from frist branch
        let resultType = try context + pattern ~> matchingType |- inExpr
        // check in other branches
        for (pattern, inExpr) in branches[1...] {
            try context + pattern ~> matchingType |- inExpr <= resultType
        }
        // exhaustiveness check (approximate)
        guard branches.map(\.0) |? matchingType else {
            throw Code.error(.nonexhaustiveMatch(expr, for: matchingType))
        }
        return resultType

    case let .list(elems):
        guard let first = elems.first else {
            throw Code.error(.ambiguosList(expr))
        }
        let ofType = try context |- first
        try elems.forEach { try context |- $0 <= ofType }
        return .list(of: ofType)

    case let .consList(head, tail):
        let ofType = try context |- head
        try context |- tail <= .list(of: ofType)
        return .list(of: ofType)

    case let .head(ofExpr):
        let exprType = try context |- ofExpr
        guard case let .list(of) = exprType else {
            throw Code.error(.notAList(actualType: exprType, in: expr))
        }
        return of

    case let .tail(ofExpr):
        let exprType = try context |- ofExpr
        guard case let .list(of) = exprType else {
            throw Code.error(.notAList(actualType: exprType, in: expr))
        }
        return .list(of: of)

    case let .isEmpty(expression):
        let exprType = try context |- expression
        guard case .list = exprType else {
            throw Code.error(.notAList(actualType: exprType, in: expr))
        }
        return .bool

    case let .variant(tag, .none):
        guard context.isEnabled(.subtyping) else {
            throw Code.error(.ambiguosVariant(expr))
        }
        return .variant([(tag, nil)])

    case let .variant(tag, .some(forExpr)):
        let type = try context |- forExpr
        guard context.isEnabled(.subtyping) else {
            throw Code.error(.ambiguosVariant(expr))
        }
        return .variant([(tag, type)])

    case let .fix(theExpr):
        let exprType = try context |- theExpr
        guard case let .function(fromTypes, toType) = exprType else {
            throw Code.error(.notAFunction(actualType: exprType, what: theExpr, in: expr))
        }
        guard fromTypes.count == 1 else {
            throw Code.error(
                .incorrectArgumentsNumber(fromTypes.count, expected: 1, for: exprType, in: expr)
            )
        }
        guard compare(fromTypes[0], toType, in: context) else {
            if context.isEnabled(.subtyping) {
                throw Code.error(.unexpectedSubtype(toType, of: fromTypes[0], in: expr))
            }
            throw Code.error(
                .unexpectedType(toType, expected: fromTypes[0], in: expr)
            )
        }
        return toType

    case let .sequence(first, second):
        try context |- first <= .unit
        return try context |- second

    case let .ref(toExpr):
        return try .reference(context |- toExpr)

    case let .deref(refExpr):
        let exprType = try context |- refExpr
        guard case let .reference(toType) = exprType else {
            throw Code.error(.notAReference(actualType: exprType, in: expr))
        }
        return toType

    case let .assign(assignee, expr):
        let assigneeType = try context |- assignee
        guard case let .reference(toType) = assigneeType else {
            throw Code.error(.notAReference(actualType: assigneeType, in: expr))
        }
        try context |- expr <= toType
        return .unit

    case .constMemory:
        throw Code.error(.ambiguousReference(expr))

    case .panic:
        guard context.isEnabled(.asBottom) else {
            throw Code.error(.ambiguousPanic(expr))
        }
        return .bottom

    case let .throw(theExpr):
        guard let throwType = context.exceptionType else {
            throw Code.error(.exceptionNotDeclared(usedIn: expr))
        }
        try context |- theExpr <= throwType
        guard context.isEnabled(.subtyping) else {
            throw Code.error(.ambiguousThrow(expr))
        }
        return .bottom

    case let .tryWith(expr, recover):
        let type = try context |- expr
        try context |- recover <= type
        return type

    case let .tryCatch(tryExpr, pattern, recover):
        let type = try context |- tryExpr
        guard let throwType = context.exceptionType else {
            throw Code.error(.exceptionNotDeclared(usedIn: expr))
        }
        try context + pattern ~> throwType |- recover <= type
        return type

    case let .typeCast(castee, asType):
        let _ = try context |- castee
        return asType

    case let .tryCastAs(tryExpr, type, pattern, newExpr, with: recover):
        let _ = try context |- tryExpr
        let type = try context + pattern ~> type |- newExpr
        try context |- recover <= type
        return type

    default:
        throw Code.unsupported(expr, description: "Inference not implemented")
    }
}

