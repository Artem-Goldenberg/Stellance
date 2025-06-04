import Stella

func check(_ type: Type, in context: GlobalContext) throws {
    func recCheck(_ type: Type) throws {
        try check(type, in: context)
    }
    func require(_ ext: KnownExtension, or other: KnownExtension? = nil) throws {
        if let other {
            try betterEnable(ext, or: other, for: type, in: context)
        } else {
            try betterEnable(ext, for: type, in: context)
        }
    }

    switch type {
    case .bool, .nat: break
    case .function(let arguments, let returnType):
        guard !arguments.isEmpty || context.isEnabled(.nullFunctions) else {
            throw Code.unsupported(
                type, description: "Zero argument function type", tryEnabling: .nullFunctions
            )
        }
        guard arguments.count <= 1 || context.isEnabled(.multiFunctions) else {
            throw Code.unsupported(
                type, description: "Multi argument function type", tryEnabling: .multiFunctions
            )
        }
        try arguments.forEach(recCheck)
        try check(returnType, in: context)

    case .unit: try require(.unitType)

    case .tuple(let array) where array.count == 2:
        try require(.pairs, or: .tuples)
        try array.forEach(recCheck)

    case .tuple(let array):
        try require(.tuples)
        try array.forEach(recCheck)

    case .record(let fields):
        try require(.records)
        let dupNames = fields.map(\.0).allDuplicates
        guard dupNames.isEmpty else {
            throw Code.error(.duplicateTypeFields(dupNames, in: type))
        }
        try fields.map(\.1).forEach(recCheck)

    case .sum(let left, let right):
        try require(.sumTypes)
        try recCheck(left)
        try recCheck(right)

    case .list(let of):
        try require(.lists)
        try recCheck(of)

    case .variant(let tags):
        try require(.variants)

        let dupTags = tags.map(\.0).allDuplicates
        guard dupTags.isEmpty else {
            throw Code.error(.duplicateTypeTags(dupTags, in: type))
        }

        if tags.anySatisfy({ $0.1 == nil }) {
            try require(.nullVariants)
        }

        try tags.compactMap(\.1).forEach(recCheck)

    default:
        throw Code.unsupported(type, tryEnabling: nil)
    }
}

