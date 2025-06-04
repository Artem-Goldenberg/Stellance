import Stella

func check(_ pattern: Pattern, in context: GlobalContext) throws {
    func recCheck(_ pattern: Pattern) throws {
        try check(pattern, in: context)
    }
    func require(_ ext: KnownExtension) throws {
        try betterEnable(ext, for: pattern, in: context)
    }

    switch pattern {
    case .var: break

    case .false, .true, .unit, .int:
        try require(.structuralPatterns)

    case .succ(let pattern):
        try require(.structuralPatterns)
        try check(pattern, in: context)

    case let .tuple(patterns):
        try require(.structuralPatterns)
        try patterns.forEach { try check($0, in: context) }

    case let .record(patterns):
        try require(.structuralPatterns)
        let dupNames = patterns.map(\.0).allDuplicates
        guard dupNames.isEmpty else {
            throw Code.error(.duplicatePatternFields(dupNames, in: pattern))
        }
        try patterns.map(\.1).forEach(recCheck)

    case let .inl(pattern), let .inr(pattern):
        try require(.sumTypes)
        try recCheck(pattern)

    case let .list(patterns):
        try require(.structuralPatterns)
        try patterns.forEach(recCheck)

    case let .cons(head, tail):
        try require(.structuralPatterns)
        try recCheck(head)
        try recCheck(tail)

    case .variant(_, .none):
        try require(.nullVariants)

    case let .variant(_, .some(pattern)):
        try require(.variants)
        try recCheck(pattern)

    case let .ascription(pattern, type):
        try require(.patternAscriptions)
        try check(type, in: context)
        try recCheck(pattern)

    default:
        throw Code.unsupported(pattern, tryEnabling: nil)
    }
}

extension Pattern {
    var isVariable: Bool {
        guard case .var = self else { return false }
        return true
    }
}
