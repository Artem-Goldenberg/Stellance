import Foundation
import Stella

func quit(with message: String) -> Never {
    print(message)
    exit(EXIT_FAILURE)
}

var standardError = FileHandle.standardError

func warning(_ message: String) {
    print("Warning: \(message)", to: &standardError)
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


enum Code: Error {
    case error(_ code: TypeCheckError)
    case unsupported(
        _ syntax: Syntax,
        description: String? = nil,
        tryEnabling: KnownExtension? = nil
    )
}

func staticCheck(the program: Program) throws {
    let extensionNames: [String] = program.extensions.flatMap(\.names).map(\.value)

    let enabledExtensions: [KnownExtension] = extensionNames.compactMap { name in
        guard let ext = KnownExtension(rawValue: name)
        else {
            warning("Unrecognized extension: \(name)")
            return nil
        }
        return ext
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

    for declaration in program.declarations {
        try check(declaration, in: context)
    }

    try context |- program
}

do {
    try staticCheck(the: program)

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

    case .error(let code):
        print(code.code)
        print()
        if let generalMessage = code.message {
            print(generalMessage)
        }
        print("\n")
    }

    exit(EXIT_FAILURE)

} catch let error {
    print("Unknown error: \(error.localizedDescription)")
    exit(EXIT_FAILURE)
}

extension FileHandle: @retroactive TextOutputStream {
  public func write(_ string: String) {
    let data = Data(string.utf8)
    self.write(data)
  }
}
