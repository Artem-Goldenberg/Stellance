import Stella

func check(_ decl: Declaration, in context: GlobalContext) throws {
    switch decl {
    case .function(
        let annotations, _, let parameters,
        let returnType, let throwTypes, let body, let `return`
    ):
        guard annotations.isEmpty else {
            throw Code.unsupported(
                decl, description: "Function with annotations", tryEnabling: nil
            )
        }
        guard throwTypes.isEmpty else {
            throw Code.unsupported(
                decl, description: "Function with throw types", tryEnabling: nil
            )
        }
        guard let returnType else {
            throw Code.unsupported(
                decl, description: "Function with no return type", tryEnabling: nil
            )
        }
        guard !parameters.isEmpty || context.isEnabled(.nullFunctions) else {
            throw Code.unsupported(
                decl,
                description: "Functions with no parameters",
                tryEnabling: .nullFunctions
            )
        }
        guard parameters.count == 1 || context.isEnabled(.multiFunctions) else {
            throw Code.unsupported(
                decl,
                description: "Functions with multiple parameters",
                tryEnabling: .multiFunctions
            )
        }
        guard body.isEmpty || context.isEnabled(.nestedDeclarations) else {
            throw Code.unsupported(
                decl,
                description: "Function with statements",
                tryEnabling: .nestedDeclarations
            )
        }

        try parameters.map(\.type).forEach { try check($0, in: context) }

        try throwTypes.forEach { try check($0, in: context) }
        try check(returnType, in: context)

        try body.forEach { try check($0, in: context) }
        try check(`return`, in: context)

    case .genericFunction(
        let annotations, let name, let typeVariables, let parameters,
        let returnType, let throwTypes, let body, let `return`
    ):
        let _ = (annotations, name, typeVariables, parameters, returnType, throwTypes, body, `return`)
        throw Code.unsupported(decl, description: "Generic functions", tryEnabling: nil)

    case .typeAlias(_, _):
        throw Code.unsupported(decl, tryEnabling: nil)

    case .exceptionType(_):
        throw Code.unsupported(decl, tryEnabling: nil)

    case .exceptionVariant(_, _):
        throw Code.unsupported(decl, tryEnabling: nil)

    }
}

func betterEnable(
    _ ext: KnownExtension, or others: KnownExtension...,
    for syntax: Syntax, in context: GlobalContext
) throws {
    guard context.isEnabled(ext) || others.anySatisfy(context.isEnabled) else {
        throw Code.unsupported(syntax, tryEnabling: ext)
    }
}
