import Stella

func check(_ expr: Expression, in context: GlobalContext) throws {
    func recCheck(_ expr: Expression) throws {
        try check(expr, in: context)
    }
    func require(
        _ ext: KnownExtension,
        or other: KnownExtension? = nil,
        or another: KnownExtension? = nil
    ) throws {
        guard let other else {
            try betterEnable(ext, for: expr, in: context)
            return
        }
        guard let another else {
            try betterEnable(ext, or: other, for: expr, in: context)
            return
        }
        try betterEnable(ext, or: other, another, for: expr, in: context)
    }

    switch expr {
    case .var: break
    case .constTrue, .constFalse: break
    case let .if(cond, onTrue, onFalse):
        try recCheck(cond)
        try recCheck(onTrue)
        try recCheck(onFalse)

    case .constInt(1...):
        try require(.natLiterals)
    case .constInt(0): break

    case let .application(callee, arguments):
        try recCheck(callee)
        try arguments.forEach(recCheck)

    case let .succ(expr): try recCheck(expr)
    case let .isZero(expr): try recCheck(expr)

    case let .natRec(iters, ini, step):
        try recCheck(iters)
        try recCheck(ini)
        try recCheck(step)

    case let .abstraction(parameters, `return`):
        guard !parameters.isEmpty || context.isEnabled(.nullFunctions) else {
            throw Code.unsupported(
                expr, description: "Zero argument lambdas", tryEnabling: .nullFunctions
            )
        }
        guard parameters.count <= 1 || context.isEnabled(.multiFunctions) else {
            throw Code.unsupported(
                expr, description: "Multi argument lambdas", tryEnabling: .multiFunctions
            )
        }
        try parameters.map(\.type).forEach { try check($0, in: context) }
        try recCheck(`return`)

    case .constUnit: try require(.unitType)

    case let .tuple(elems) where elems.count == 2:
        try require(.pairs, or: .tuples)
        try elems.forEach(recCheck)

    case let .tuple(elems):
        try require(.tuples)
        try elems.forEach(recCheck)

    case let .dotTuple(indexee, 1...2):
        try require(.pairs, or: .tuples)
        try recCheck(indexee)

    case let .dotTuple(indexee, 2...):
        try require(.tuples)
        try recCheck(indexee)

    case let .dotTuple(_, index):
        throw Code.unsupported(expr, description: "Bad tuple index: \(index)")

    case let .record(fields):
        try require(.records)
        let dupNames = fields.map(\.0).allDuplicates
        guard dupNames.isEmpty else {
            throw Code.error(.duplicateFields(dupNames, in: expr))
        }
        try fields.map(\.1).forEach(recCheck)

    case let .dotRecord(indexee, _):
        try require(.records)
        try recCheck(indexee)

    case let .let(bindings, inExpr) where bindings.count == 1:
        try require(.letBindings)
        if !bindings.allSatisfy(\.0.isVariable) {
            try require(.letPatterns)
        }
        // check patterns
        try bindings.map(\.0).forEach { try check($0, in: context) }
        // check expressions
        try bindings.map(\.1).forEach(recCheck)
        try recCheck(inExpr)

    case let .letrec(bindings, inExpr) where bindings.count == 1:
        try require(.letrec)
        if !bindings.allSatisfy(\.0.isVariable) {
            try require(.letPatterns)
        }
        // check patterns
        try bindings.map(\.0).forEach { try check($0, in: context) }
        // check expressions
        try bindings.map(\.1).forEach(recCheck)
        try recCheck(inExpr)

    case let .typeAscription(ascriptee, type):
        try require(.typeAscriptions)
        try recCheck(ascriptee)
        try check(type, in: context)

    case let .inl(expression), let .inr(expression):
        try require(.sumTypes)
        try recCheck(expression)

    case let .match(matchee, branches):
        guard !branches.isEmpty else {
            throw Code.error(.emptyMatch(expr))
        }

        try recCheck(matchee)
        try branches.map(\.0).forEach { try check($0, in: context) }
        try branches.map(\.1).forEach(recCheck)

    case let .list(elems):
        try require(.lists)
        try elems.forEach(recCheck)
    case let .consList(head, tail):
        try require(.lists)
        try recCheck(head)
        try recCheck(tail)
    case let .head(expression):
        try require(.lists)
        try recCheck(expression)
    case let .tail(expression):
        try require(.lists)
        try recCheck(expression)
    case let .isEmpty(expression):
        try require(.lists)
        try recCheck(expression)

    case .variant(_, .none):
        try require(.nullVariants)

    case let .variant(_, .some(expr)):
        try require(.variants)
        try recCheck(expr)

    case let .fix(expr):
        try require(.fixpoint)
        try recCheck(expr)

    default:
        throw Code.unsupported(expr, description: "Not supported yet")

    }
}
