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

infix operator |-: ContextPrecedence
infix operator <=: TypeCheckPrecedence
infix operator =>: TypeCheckPrecedence

struct TypeCheck {
    let node: Expression
    let type: Type
}


func <=(node: Expression, type: Type) -> TypeCheck {
    return TypeCheck(node: node, type: type)
}

func expect(_ type: Type, actual: Type, in expr: Expression) throws {
    guard type == actual else {
        throw Code.error(
            .unexpectedType,
            message:
                """
                Expected type: 
                    \(type.code)
                Actual type: 
                    \(actual.code)
                In expression: 
                    \(expr.code)
                """
        )
    }
}

/// Type inference
func |-(context: Context, expression: Expression) throws -> Type {
    switch expression {
    case .var(let identifier):
        guard let type = context.type(of: identifier) else {
            throw Code.error(.undefinedVariable, message: "\(identifier.value)")
        }
        return type
    case .constTrue, .constFalse: return .bool
    case .constUnit: return .unit
//    case .if(let condition, let onTrue, let onFalse):
//        try context |- condition <= .bool
//        let type1 = try context |- onTrue
//        let type2 = try context |- onFalse
//        try expect(type1, actual: type2, in: expression)
//        return type1
    case .constInt(0): return .nat
    case .succ(let nat), .pred(let nat):
        try context |- nat <= .nat
        return .nat
    case .isZero(let nat):
        try context |- nat <= .nat
        return .bool
//    case .natRec(let num, let ini, let step):
//        try context |- num <= .nat
//        let type = try context |- ini
//        try context |- step <= .function(from: [.nat], to: .function(from: [type], to: type))
//        return type
    default:
        throw Code.unsupported(expression)
    }
}

func |-(context: Context, check: TypeCheck) throws {
    let type = check.type

    switch check.node {
    case let .if(condition, onTrue, onFalse):
        try context |- condition <= .bool
        try context |- onTrue <= type
        try context |- onFalse <= type

    case let .natRec(numExpr, iniExpr, stepExpr):
        try context |- numExpr <= .nat
        try context |- iniExpr <= type
        try context |- stepExpr <= .function(from: [.nat], to: .function(from: [type], to: type))

    case let .abstraction(parameters, body):
        guard case let .function(paramTypes, returnType) = type else {
            throw Code.error(
                .unexpectedLambda,
                message: "Expected type: \(type) cannot be assigned to lambda: \(check.node)"
            )
        }
        guard paramTypes.count == parameters.count else {
            throw Code.error(
                .unexpectedParametersNumber,
                message:
                "Expected \(paramTypes.count), but got \(parameters.count), in: \(check.node)"
            )
        }
        for (param, type) in zip(parameters, paramTypes) {
            guard param.type == type else {
                throw Code.error(
                    .unexpectedParameterType,
                    message: "Expected \(type), instead have: \(param.type), in: \(check.node)"
                )
            }
        }
        // this is sick!!!
        try parameters.reduce(context, +) |- body <= returnType

    case let .application(callee, arguments):
        let calleeType = try context |- callee
        guard case let .function(paramTypes, returnType) = calleeType else {
            throw Code.error(
                .notAFunction,
                message:
                    """
                    Callee is not a function, instead it's type is: \(calleeType),
                    need a functional callee type for: \(check.node)
                    """
            )
        }
        guard arguments.count == paramTypes.count else {
            throw Code.error(
                .incorrectArgumentsNumber,
                message:
                    """
                    Was expecting \(paramTypes.count) arguments,
                    because \(callee) is of type \(calleeType),
                    instead have \(arguments.count) arguments
                    in call: \(check.node)
                    """
            )
        }
        for (argument, type) in zip(arguments, paramTypes) {
            try context |- argument <= type
        }
        try expect(type, actual: returnType, in: check.node)


    default:
        // try infering type instead
        let inferred = try context |- check.node
        try expect(type, actual: inferred, in: check.node)
    }
}

extension String {
    init(byDumping stuff: Any) {
        var str = String()
        dump(stuff, to: &str)
        self = str
    }
}
