import Stella

enum TypeCheckError: Error {
    case missingMain
    case undefinedVariable(Identifier)
    case unexpectedType(Type, expected: Type, in: Expression)
    case notAFunction(actualType: Type, what: Expression, in: Expression)
    case notATuple(actualType: Type, in: Expression)
    case notARecord(actualType: Type, in: Expression)
    case notAList(actualType: Type, in: Expression)
    case unexpectedLambda(Expression, expected: Type)
    case unexpectedParameterType(
        Type, expected: Type,
        for: Identifier, calleeType: Type,
        in: Expression
    )
    case unexpectedTuple(Expression, expected: Type)
    case unexpectedRecord(Expression, expected: Type)
    case unexpectedVariant(Expression, expected: Type)
    case unexpectedList(Expression, expected: Type)
    case unexpectedInjection(Expression, expected: Type)
    case missingFields([Identifier], for: Type, in: Expression)
    case unexpectedFields([Identifier], for: Type, in: Expression)
    case unexpectedFieldAccess(Identifier, for: Type, in: Expression)
    case unexpectedTag(Identifier, for: Type, in: Expression)
    case unexpectedIndex(Int, for: Type, in: Expression)
    case unexpectedLength(Int, expected: Int, for: Type, in: Expression)
    case ambiguosSum(Expression)
    case ambiguosVariant(Expression)
    case ambiguosList(Expression)
    case ambiguosPattern(Pattern)
    case emptyMatch(Expression)
    case nonexhaustiveMatch(Expression, for: Type)
    case unexpectedPattern(Pattern, for: Type)
    case duplicateFields([Identifier], in: Expression)
    case duplicateTypeFields([Identifier], in: Type)
    case duplicatePatternFields([Identifier], in: Pattern)
    case duplicateTypeTags([Identifier], in: Type)
    case incorrectMainArity(Int)
    case incorrectArgumentsNumber(Int, expected: Int, for: Type, in: Expression)
    case unexpectedParametersNumber(Int, expected: Int, for: Type, in: Expression)

    case unexpectedData(for: Identifier, in: Expression, expected: Type)
    case missingData(for: Identifier, of: Type, in: Expression, expected: Type)

    case unexpectedNonNullVariantPattern(for: Identifier, in: Pattern, type: Type)
    case unexpectedNullVariantPattern(for: Identifier, missedType: Type, in: Pattern, type: Type)

    case exceptionNotDeclared(usedIn: Expression)
    case ambiguousThrow(Expression)
    case ambiguousReference(Expression)
    case ambiguousPanic(Expression)
    case notAReference(actualType: Type, in: Expression)
    case unexpectedReference(Expression, expected: Type)
    case unexpectedAddress(Expression, expected: Type)
    case unexpectedSubtype(Type, of: Type, in: Expression)
}

extension TypeCheckError {
    var code: String {
        switch self {
        case .missingMain: "ERROR_MISSING_MAIN"
        case .undefinedVariable: "ERROR_UNDEFINED_VARIABLE"
        case .unexpectedType: "ERROR_UNEXPECTED_TYPE_FOR_EXPRESSION"
        case .notAFunction: "ERROR_NOT_A_FUNCTION"
        case .notATuple: "ERROR_NOT_A_TUPLE"
        case .notARecord: "ERROR_NOT_A_RECORD"
        case .notAList: "ERROR_NOT_A_LIST"
        case .unexpectedLambda: "ERROR_UNEXPECTED_LAMBDA"
        case .unexpectedParameterType: "ERROR_UNEXPECTED_TYPE_FOR_PARAMETER"
        case .unexpectedTuple: "ERROR_UNEXPECTED_TUPLE"
        case .unexpectedRecord: "ERROR_UNEXPECTED_RECORD"
        case .unexpectedVariant: "ERROR_UNEXPECTED_VARIANT"
        case .unexpectedList: "ERROR_UNEXPECTED_LIST"
        case .unexpectedInjection: "ERROR_UNEXPECTED_INJECTION"
        case .missingFields: "ERROR_MISSING_RECORD_FIELDS"
        case .unexpectedFields: "ERROR_UNEXPECTED_RECORD_FIELDS"
        case .unexpectedFieldAccess: "ERROR_UNEXPECTED_FIELD_ACCESS"
        case .unexpectedTag: "ERROR_UNEXPECTED_VARIANT_LABEL"
        case .unexpectedIndex: "ERROR_TUPLE_INDEX_OUT_OF_BOUNDS"
        case .unexpectedLength: "ERROR_UNEXPECTED_TUPLE_LENGTH"
        case .ambiguosSum: "ERROR_AMBIGUOUS_SUM_TYPE"
        case .ambiguosVariant: "ERROR_AMBIGUOUS_VARIANT_TYPE"
        case .ambiguosList: "ERROR_AMBIGUOUS_LIST"
        case .ambiguosPattern: "ERROR_AMBIGUOUS_PATTERN_TYPE"
        case .emptyMatch: "ERROR_ILLEGAL_EMPTY_MATCHING"
        case .nonexhaustiveMatch: "ERROR_NONEXHAUSTIVE_MATCH_PATTERNS"
        case .unexpectedPattern: "ERROR_UNEXPECTED_PATTERN_FOR_TYPE"
        case .duplicateFields: "ERROR_DUPLICATE_RECORD_FIELDS"
        case .duplicateTypeFields: "ERROR_DUPLICATE_RECORD_TYPE_FIELDS"
        case .duplicatePatternFields: "ERROR_DUPLICATE_RECORD_PATTERN_FIELDS"
        case .duplicateTypeTags: "ERROR_DUPLICATE_VARIANT_TYPE_FIELDS"
        case .incorrectMainArity: "ERROR_INCORRECT_ARITY_OF_MAIN"
        case .incorrectArgumentsNumber: "ERROR_INCORRECT_NUMBER_OF_ARGUMENTS"
        case .unexpectedParametersNumber: "ERROR_UNEXPECTED_NUMBER_OF_PARAMETERS_IN_LAMBDA"
        case .unexpectedData: "ERROR_UNEXPECTED_DATA_FOR_NULLARY_LABEL"
        case .missingData: "ERROR_MISSING_DATA_FOR_LABEL"
        case .unexpectedNonNullVariantPattern: "ERROR_UNEXPECTED_NON_NULLARY_VARIANT_PATTERN"
        case .unexpectedNullVariantPattern: "ERROR_UNEXPECTED_NULLARY_VARIANT_PATTERN"
        case .exceptionNotDeclared: "ERROR_EXCEPTION_TYPE_NOT_DECLARED"
        case .ambiguousThrow: "ERROR_AMBIGUOUS_THROW_TYPE"
        case .ambiguousReference: "ERROR_AMBIGUOUS_REFERENCE_TYPE"
        case .ambiguousPanic: "ERROR_AMBIGUOUS_PANIC_TYPE"
        case .notAReference: "ERROR_NOT_A_REFERENCE"
        case .unexpectedReference: "ERROR_UNEXPECTED_REFERENCE"
        case .unexpectedAddress: "ERROR_UNEXPECTED_MEMORY_ADDRESS"
        case .unexpectedSubtype: "ERROR_UNEXPECTED_SUBTYPE"
        }
    }
}

extension TypeCheckError {
    var message: String? {
        switch self {
        case .missingMain:
            "main function is missing from the program"
        case let .incorrectMainArity(n):
            "main function must have one and only one parameter, instead it has \(n)"
        case let .undefinedVariable(name):
            "Undefined variable: \(name.code)"
        case let .unexpectedType(actual, expected, in: expr):
            """
            Expected type: \(wrap: expected.code)
            Instead have: \(wrap: actual.code)
            In expression: 
                \(indented: expr.code)
            """
        case let .notAFunction(actualType, what, in: expr):
            """
            Expression: \(wrap: what.code) is expected to have a function type
            But instead it's type is: \(wrap: actualType.code)
            In expression:
                \(indented: expr.code)
            """
        case let .incorrectArgumentsNumber(actual, expected, for: calleeType, in: expr):
            """
            Was expecting \(expected) argument\(expected != 1 ? "s" : ""), \
            instead got \(actual) argument\(actual != 1 ? "s" : "")
            For the function of type: \(wrap: calleeType.code)
            In expression: 
                \(indented: expr.code)
            """
        case let .unexpectedLambda(expr, expected: type):
            """
            Expected type: \(wrap: type.code) 
            cannot be assigned to lambda: 
                \(indented: expr.code)
            """
        case let .unexpectedParametersNumber(actual, expected, for: calleeType, in: expr):
            """
            Expected \(expected) parameter\(expected != 1 ? "s" : ""), \
            instead got \(actual) parameter\(actual != 1 ? "s" : "")
            For type: \(wrap: calleeType.code)
            In expression: \(wrap: expr.code)
            """
        case let .unexpectedParameterType(type, expected, for: name, calleeType, in: expr):
            """
            Unexpected type for parameter \(name.code) 
            Expecting type: \(wrap: expected.code)
            Actual type: \(wrap: type.code)
            For overall function type: \(wrap: calleeType.code)
            In lambda expression: \(wrap: expr.code)
            """
        case let .notATuple(actualType, in: expr):
            """
            Expected a tuple type instead of:
                \(indented: actualType.code)
            In expression:
                \(indented: expr.code)
            """
        case let .unexpectedIndex(index, for: type, in: expr):
            """
            Unexpected index: \(index)
            for a tuple of type: \(wrap: type.code)
            In expression: \(wrap: expr.code)
            """
        case let .unexpectedTuple(expr, expected: type):
            """
            Expected type: \(wrap: type.code)
            cannot be assigned to tuple in: \(wrap: expr.code)
            """
        case let .unexpectedLength(len, expected, for: type, in: expr):
            """
            Unexpected lenght of tuple: \(len), 
            expecting length \(expected), because of type:
                \(indented: type.code)
            In expression: \(wrap: expr.code)
            """
        case let .notARecord(actualType, in: expr):
            """
            Expected a record type instead of: \(wrap: actualType.code)
            In expression: \(wrap: expr.code)
            """
        case let .unexpectedFieldAccess(name, for: type, in: expr):
            """
            Unexpected field name: '\(name.code)'
            for a record of type: \(wrap: type.code)
            In expression: \(wrap: expr.code)
            """
        case let .unexpectedRecord(expr, expected: type):
            """
            Expected type: \(wrap: type.code)
            cannot be assigned to record in: \(wrap: expr.code)
            """
        case let .missingFields(fields, for: type, in: expr):
            """
            Missing record fields: \(enum: fields)
            Required by type: \(wrap: type.code)
            In expression: \(wrap: expr.code)
            """
        case let .unexpectedFields(fields, for: type, in: expr):
            """
            Extra record fields: \(enum: fields)
            Required by type: \(wrap: type.code)
            In expression: \(wrap: expr.code)
            """
        case let .duplicateFields(fields, in: expr):
            """
            Duplicate record fields: \(enum: fields)
            In expression: \(wrap: expr.code)
            """
        case let .duplicateTypeFields(fields, in: type):
            """
            Duplicate record fields: \(enum: fields)
            In type: \(wrap: type.code)
            """
        case let .duplicatePatternFields(fields, in: pattern):
            """
            Duplicate record fields: \(enum: fields)
            In pattenr: \(wrap: pattern.code)
            """
        case let .duplicateTypeTags(tags, in: type):
            """
            Duplicate variant tags: \(enum: tags)
            In a variant type: \(wrap: type.code)
            """
        case let .emptyMatch(expr):
            """
            Match expression with zero alternatives: 
                \(indented: expr.code)
            """
        case let .unexpectedPattern(pattern, for: type):
            """
            Pattern: \(wrap: pattern.code)
            cannot be used to match against type: \(wrap: type.code)
            """
        case let .unexpectedInjection(expr, expected):
            """
            Unexpected inl or inr tag: \(wrap: expr.code)
            Expected expression of type: \(wrap: expected.code)
            """
        case let .ambiguosSum(expr):
            """
            Cannot infer the other half of the sum type in: \(wrap: expr.code)
            """
        case let .nonexhaustiveMatch(expr, for: type):
            """
            Not all cases of type: \(wrap: type.code)
            Are covered by: \(wrap: expr.code)
            """
        case let .ambiguosPattern(pattern):
            """
            Cannot infer types for variables in: \(wrap: pattern.code)
            """
        case let .unexpectedList(expr, expected):
            """
            Expected expression of type: \(wrap: expected.code)
            Instead of a list: \(wrap: expr.code)
            """
        case let .ambiguosList(expr):
            """
            Cannot infer type of the list: \(wrap: expr.code)
            """
        case let .notAList(actual, in: expr):
            """
            Actual type: \(wrap: actual.code)
            Is not a list type, which is required in:
                \(indented: expr.code)
            """
        case let .unexpectedVariant(expr, expected):
            """
            Expected expression of type: \(wrap: expected.code)
            Instead of a variant expresssion: \(wrap: expr.code)
            """
        case let .ambiguosVariant(expr):
            """
            Cannot infer type of a variant expression: \(wrap: expr.code)
            """
        case let .unexpectedTag(name, for: type, in: expr):
            """
            Variant label: '\(name.code)' wasn't expected 
            for a variant type: \(wrap: type.code)
            In expression: \(wrap: expr.code)
            """
        case let .missingData(for: tag, of: type, in: expr, expected):
            """
            Variant label: '\(tag.code)' is a null label, 
            but expression of type: \(wrap: type.code)
            was expected for a variant type: \(wrap: expected.code)
            In expression: \(wrap: expr.code)
            """
        case let .unexpectedData(for: tag, in: expr, expected):
            """
            Null variant label: '\(tag.code)' contains an expression, but it shouldn't
            for a variant of type: \(wrap: expected.code)
            In expresssion: \(wrap: expr.code)
            """
        case let .unexpectedNullVariantPattern(for: tag, missedType, in: pattern, type):
            """
            Pattern: \(wrap: pattern.code) 
            suggests that a variant label: '\(tag.code)' must be a nullary label
            but is should match the type: \(wrap: missedType.code)
            according to the matching type: \(wrap: type.code)
            """
        case let .unexpectedNonNullVariantPattern(for: tag, in: pattern, type):
            """
            Pattern: \(wrap: pattern.code)
            provides a pattern to match for a label: '\(tag.code)', 
            but this tag must be null according to a matching type: \(wrap: type.code)
            """

        case let .unexpectedAddress(expr, expected):
            """
            Expected expression of type: \(wrap: expected.code)
            Instead have a reference expression:
                \(indented: expr.code)
            """
        case let .notAReference(actualType, in: expr):
            """
            Expected an expression of a reference type, 
            instead have expression of type: \(wrap: actualType.code)
            In expression:
                \(indented: expr.code)
            """
        case let .ambiguousPanic(expr):
            """
            Cannot infer type for a panic expression: 
                \(indented: expr.code)
            """
        case let .exceptionNotDeclared(usedIn: expr):
            """
            No exception is declared, but exceptions are used in:
                \(indented: expr.code)
            """
        case let .ambiguousThrow(expr):
            """
            Cannot infer type for a throw expression:
                \(indented: expr.code)
            """
        case let .ambiguousReference(expr):
            """
            Cannot infer type for a reference expression:
                \(indented: expr.code)
            """
        case let .unexpectedSubtype(subtype, of: type, in: expr):
            """
            Type: \(wrap: subtype.code)
            Is not a subtype of: \(wrap: type.code)
            In expression:
                \(indented: expr.code)
            """
        case let .unexpectedReference(expr, expected: type):
            """
            Was expecting an expression of type: \(wrap: type.code)
            Instead got: \(wrap: expr.code)
            """
        }
    }
}
