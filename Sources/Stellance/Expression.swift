import Stella

precedencegroup ContextPrecedence {
    higherThan: AssignmentPrecedence
    lowerThan: TernaryPrecedence
    associativity: none
}

precedencegroup TypeCheckPrecedence {
    higherThan: ContextPrecedence
    lowerThan: LogicalDisjunctionPrecedence
    associativity: none
}

precedencegroup PatternMatchingPrecedence {
    higherThan: AdditionPrecedence
    lowerThan: MultiplicationPrecedence
    associativity: none
}

infix operator |-: ContextPrecedence
infix operator <=: TypeCheckPrecedence
infix operator ~>: PatternMatchingPrecedence
infix operator ~: ComparisonPrecedence

struct TypeCheck {
    let node: Expression
    let type: Type
}

struct Binding {
    let pattern: Pattern
    let type: Type
}

struct Typing {
    let name: Identifier
    let type: Type
}

func ~>(pattern: Pattern, type: Type) -> Binding {
    Binding(pattern: pattern, type: type)
}

func ~>(name: Identifier, type: Type) -> Typing {
    Typing(name: name, type: type)
}

func <=(node: Expression, type: Type) -> TypeCheck {
    TypeCheck(node: node, type: type)
}

func +(context: Context, parameter: Declaration.Parameter) -> LocalContext {
    LocalContext(next: context, name: parameter.name, type: parameter.type)
}

func +(context: Context, typing: Typing) -> LocalContext {
    LocalContext(next: context, name: typing.name, type: typing.type)
}

func +(context: Context, declaration: Declaration) throws -> LocalContext {
    switch declaration {
    case let .function(_, name, parameters, .some(returnType), _, _, _):
        context + name ~> .function(from: parameters.map(\.type), to: returnType)
    default:
        throw Code.unsupported(declaration)
    }
}

func ~(subtype: Type, type: Type) -> Bool {
    switch (subtype, type) {
    case (_, .top): return true
    case (.bottom, _): return true

    case let (.function(s1, t1), .function(s2, t2)):
        return t1 ~ t2 && s1.count == s2.count && zip(s2, s1).allSatisfy(~)

    // { a : Nat, b: Bool } <: { a : Int }
    case let (.record(fields1), .record(fields2)):
        let fields = Dictionary(uniqueKeysWithValues: fields1)
        return fields2.allSatisfy { (name, type) in
            guard let subtype = fields[name] else { return false }
            return subtype ~ type
        }

    // <| a <: Nat |> <: <| a
    case let (.variant(tags1), .variant(tags2)):
        let tags = Dictionary(uniqueKeysWithValues: tags2)
        return tags1.allSatisfy { (label, subtype) in
            guard let type = tags[label] else { return false }
            switch (subtype, type) {
            case let (.some(subtype), .some(type)):
                return subtype ~ type
            case (.none, .none):
                return true
            default:
                return false
            }
        }

    case let (.list(of1), .list(of2)):
        return of1 ~ of2

    case let (.reference(to1), .reference(to2)):
        // read and write behaviour
        return to1 ~ to2 && to2 ~ to1

    case let (.sum(l1, r1), .sum(l2, r2)):
        return l1 ~ l2 && r1 ~ r2

    case let (.tuple(ts1), .tuple(ts2)):
        return ts1.count == ts2.count && zip(ts1, ts2).allSatisfy(~)

    default:
        // if no other constructors match, use syntactic equality
        return subtype == type
    }
}

func expect(_ type: Type, actual: Type, in expr: Expression) throws {
    guard type == actual else {
        throw Code.error(
            .unexpectedType(actual, expected: type, in: expr)
        )
    }
}

func |-(context: GlobalContext, program: Program) throws {
    guard let main = context.globalVariables["main"]
    else { throw Code.error(.missingMain) }

    guard case .function(let parameters, _) = main else {
        throw Code.error(.missingMain)
    }

    guard parameters.count == 1 else {
        throw Code.error(.incorrectMainArity(parameters.count))
    }

    for decl in program.declarations {
        try context |- decl
    }
}

func |-(context: Context, declaration: Declaration) throws {
    switch declaration {
    case .function(_, _, let parameters, .some(let returnType), _, let body, let `return`):
        // sick
        let contextWithParams = parameters.reduce(context, +)
        let localContext = try body.reduce(contextWithParams, +)

        for declaration in body {
            try localContext |- declaration
        }

        try localContext |- `return` <= returnType

    case .exceptionType, .exceptionVariant: break

    default:
        throw Code.unsupported(declaration)
    }
}
