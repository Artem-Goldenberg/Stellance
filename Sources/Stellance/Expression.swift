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

    default:
        throw Code.unsupported(declaration)
    }
}
