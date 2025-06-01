import Foundation
import Stella

func quit(with message: String) -> Never {
    print(message)
    exit(EXIT_FAILURE)
}

func warning(_ message: String) {
    print("Warning: \(message)")
}

let file = CommandLine.arguments[1]

//let programText = String(data: FileHandle.standardInput.availableData, encoding: .utf8)
let programText = try? String(contentsOfFile: file, encoding: .utf8)
guard let programText else {
    quit(with: "Failed to read Stella program from the standard input")
}

let program: Program
do {
    program = try Program.parser.run(sourceName: "stdin", input: programText)
} catch let error as StellaParseError {
    quit(with: error.description)
} catch let error {
    quit(with: error.localizedDescription)
}

let extensionNames: [String] = program.extensions.flatMap(\.names).map(\.value)

let enabledExtensions: [KnownExtension] = extensionNames.compactMap { name in
    guard let ext = KnownExtension(rawValue: String(name))
    else {
        warning("Unrecognized extension: \(name)")
        return nil
    }
    return ext
}

print()

enum Code: Error {
    case unsupported(
        _ syntax: Syntax,
        description: String? = nil,
        tryEnabling: KnownExtension? = nil
    )
    case error(_ code: TypeCheckError, message: String? = nil)
}

let declarationTypes: [(Identifier, Type)] = try program.declarations.map { decl in
    switch decl {
    case .function(_, let name, let parameters, .some(let returnType), _, _, _):
        (
            name,
            Type.function(from: parameters.map(\.type), to: returnType)
        )
    default:
        throw Code.unsupported(decl)
    }
}

let context = GlobalContext(
    globalVariables: .init(uniqueKeysWithValues: declarationTypes),
    enabledExntesions: enabledExtensions
)

func |-(context: GlobalContext, program: Program) throws {
    guard let main = context.globalVariables.first(where: { $0.key.value == "main" })?.value
    else { throw Code.error(.missingMain) }

    guard case .function(let parameters, _) = main else {
        throw Code.error(.missingMain)
    }

    guard parameters.count == 1 else {
        throw Code.error(.incorrectMainArity)
    }

    for decl in program.declarations {
        switch decl {
        case .function(_, _, let parameters, .some(let returnType), _, _, let `return`):
            try parameters.reduce(context, +) |- `return` <= returnType
        default:
            throw Code.unsupported(decl)
        }
    }
}

do {

    for declaration in program.declarations {
        try check(declaration, in: context)
    }

    try context |- program

} catch let error as Code {

    switch error {

    case .unsupported(let what, let description, let tryEnabling):
        print("(kind of a) SYNTAX ERROR:\n")

        print(what.code)
        if let description {
            print(description, terminator: " ")
        }

        print("is not supported\n")

        if let tryEnabling {
            print("Try enabling \(tryEnabling)\n")
        }

    case .error(let code, let message):
        print(code.code)
        if let generalMessage = code.message {
            print(generalMessage)
        }
        if let message {
            print(message)
        }
        print()
    }

    exit(EXIT_FAILURE)

} catch let error {
    print("Unknown error: \(error.localizedDescription)")
    exit(EXIT_FAILURE)
}
