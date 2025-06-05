import Stella

enum KnownExtension: String, CustomStringConvertible, CaseIterable {
    case unitType = "unit-type"
    case pairs
    case tuples
    case records
    case letBindings = "let-bindings"
    case letPatterns = "let-patterns"
    case letManyVars = "let-many-bindings"
    case typeAscriptions = "type-ascriptions"
    case sumTypes = "sum-types"
    case lists
    case variants
    case fixpoint = "fixpoint-combinator"

    case natLiterals = "natural-literals"
    case nullFunctions = "nullary-functions"
    case multiFunctions = "multiparameter-functions"
    case nestedDeclarations = "nested-function-declarations"
    case structuralPatterns = "structural-patterns"
    case nullVariants = "nullary-variant-labels"
    case letrec = "letrec-bindings"
    case patternAscriptions = "pattern-ascriptions"

    case sequencing
    case references
    case panic
    case exceptions

    case exceptionTypeDeclaraions = "exception-type-declaration"
    case openVariantExceptions = "open-variant-exceptions"

    case subtyping = "structural-subtyping"

    case top = "top-type"
    case bot = "bottom-type"
    case asBottom = "ambiguous-type-as-bottom"

    case cast = "type-cast"
    case tryCast = "try-cast-as"
    case castPatterns = "type-cast-patterns"


    var description: String {
        "#\(self.rawValue)"
    }
}

protocol Context {
    func type(of node: Identifier) -> Type?

    func isEnabled(_ ext: KnownExtension) -> Bool

    var exceptionType: Type? { get }
}

struct GlobalContext: Context {
    let globalVariables: [Identifier: Type]
    let enabledExntesions: [KnownExtension]

    let exceptionType: Type?

    func type(of node: Identifier) -> Type? {
        return globalVariables[node]
    }

    func isEnabled(_ ext: KnownExtension) -> Bool {
        enabledExntesions.contains(ext)
    }
}

struct LocalContext: Context {
    let next: Context
    let name: Identifier
    let type: Type

    func type(of node: Identifier) -> Type? {
        if (node == name) { return type }
        return next.type(of: node)
    }

    func isEnabled(_ ext: KnownExtension) -> Bool {
        next.isEnabled(ext)
    }

    var exceptionType: Type? {
        next.exceptionType
    }
}
