import Testing
import Foundation

import Stella
@testable import Stellance

@Test(
    "Stella static analyzer checks out tests",
    arguments: okPrograms.filter(usesKnownExtensions).sorted()
)
func okConformance(sourceURL: URL) throws {
    let sourceText = try String(contentsOf: sourceURL, encoding: .utf8)

    let program = try Program.parser.run(
        sourceName: sourceURL.lastPathComponent,
        input: sourceText
    )

    // expect no errors
    do {
        try staticCheck(the: program)
    } catch .unsupported as Code {
        print("Skipping: \(sourceURL)")
    }
}

@Test(
    "Stella static analyzer tests",
    arguments: badPrograms.filter(usesKnownExtensions).sorted()
)
func reportingErrors(sourceURL: URL) throws {
    let sourceText = try String(contentsOf: sourceURL, encoding: .utf8)

    let program = try Program.parser.run(
        sourceName: sourceURL.lastPathComponent,
        input: sourceText
    )

    let expectedErrorCode = sourceURL.enclosingDirectoryName

    let code: String? = try {
        do {
            try staticCheck(the: program)
            return nil
        } catch let .error(error) as Code {
            if error.code == "ERROR_AMBIGUOUS_LIST" {
                return "ERROR_AMBIGUOUS_LIST_TYPE"
            }
            return error.code
        }
    }()

    #expect(
        code == expectedErrorCode,
        "Static check should emit an error of the required type"
    )
}

let programsFolder = {
    guard let result = Bundle.module.url(forResource: "stella-tests", withExtension: nil)
    else {
        fatalError(
          """
          Cannot find the `stella-tests` repository folder, \
          make sure to load the git submodule with this repository
          """
        )
    }
    return result
}()

let okPrograms = getOkFiles(root: programsFolder, description: "Stella programs")

let badPrograms = getBadFiles(
    root: programsFolder,
    description: """
              erroneous Stella programs grouped in subfolders by the type of \
              semantic error they are emitting
              """
)

let exhaustivenessGoodTests = [
    "ne_bool.st",
    "ne_empty_list.st",
    "ne_nat_2.st",
    "ne_sum.st",
    "nonexhaustive_match.st",
    "nonexhaustive_variant.st"
]

let skippedTests = [
    "ERROR_UNEXPECTED_TUPLE_LENGTH/subtyping_tuple.st",
    "ERROR_UNEXPECTED_TUPLE_LENGTH/subtyping_tuple2.st",
    "ERROR_NOT_A_REFERENCE/deref_parameter.st",
    "ERROR_UNEXPECTED_SUBTYPE/func.st",
    "ERROR_MISSING_RECORD_FIELDS/subtyping_record.st",
    "ERROR_AMBIGUOUS_VARIANT_TYPE/ambiguous-variant-type-3.stella",
    "ERROR_UNEXPECTED_VARIANT_LABEL/subtyping_variant.st"
]

let knownExtensions = Set(KnownExtension.allCases.map(\.description))
func usesKnownExtensions(url: URL) -> Bool {
    let text = try! String(contentsOf: url, encoding: .utf8)

    if url.testDescription.starts(with: "ERROR_NONEXHAUSTIVE_MATCH_PATTERNS") {
        guard exhaustivenessGoodTests.contains(url.lastPathComponent) else {
            print("I am no exhaustive, skipping: \(url.testDescription)")
            return false
        }
    }

    if skippedTests.contains(url.testDescription) {
        print("Marked as skipped: \(url.testDescription)")
        return false
    }

    let tree: Program
    do {
        tree = try Program.parser.run(sourceName: url.lastPathComponent, input: text)
    } catch is StellaParseError {
        print("⚠️ Parsing not supported: \(url.testDescription)")
        return false
    } catch let err {
        print("⚠️ Error caugth: \(err.localizedDescription)")
        return false
    }

    let used = Set(tree.extensions.flatMap(\.names).map(\.code))

    guard used.isSubset(of: knownExtensions) else {
        print("Unknown extensions, skipping: \(url.testDescription)")
        return false
    }

    return true
}

func getOkFiles(root folder: URL, description: String) -> [URL] {
    guard let result = try? listItems(of: folder.appending(component: "ok"))
    else {
        fatalError(
            "Resource folder `\(folder)` must include a subfolder `ok` with \(description)"
        )
    }
    return result
}

func getBadFiles(root folder: URL, description: String) -> [URL] {
    guard let folders = try? listItems(of: folder.appending(component: "bad"))
    else {
        fatalError(
            "Resource folder `\(folder)` must include a subfolder `bad` with \(description)"
        )
    }
    return folders.flatMap { folder in
        guard folder.isDirectory else {
            print("Skipping \(folder)")
            return [URL]()
        }
        guard let programs = try? listItems(of: folder) else {
            fatalError("Failed to list the items of a `\(folder)`")
        }
        return programs
    }
}

func listItems(of folder: URL) throws -> [URL] {
    return try FileManager.default.contentsOfDirectory(
        at: folder, includingPropertiesForKeys: nil
    )
}

extension Code: CustomTestStringConvertible {
    public var testDescription: String {
        switch self {
        case let .error(error):
            return error.code
        case let .unsupported(syntax, description, _):
            return "\(syntax.code)\(description?.prepending(" ") ?? "")"
        }
    }
}


extension URL: @retroactive CustomTestStringConvertible {
    public var testDescription: String {
        guard pathComponents.count >= 2 else {
            return lastPathComponent
        }
        return pathComponents.suffix(2).joined(separator: "/")
    }
}

extension URL: @retroactive Comparable {
    public static func < (a: URL, b: URL) -> Bool {
        a.absoluteString < b.absoluteString
    }
}

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    var enclosingDirectoryName: String {
        guard pathComponents.count >= 2 else {
            return ""
        }
        return self.pathComponents.dropLast().last!
    }
}
