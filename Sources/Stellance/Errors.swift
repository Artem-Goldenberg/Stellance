enum TypeCheckError: Error {
    case missingMain
    case undefinedVariable
    case unexpectedType
    case notAFunction
    case notATuple
    case notARecord
    case notAList
    case unexpectedLambda
    case unexpectedParameterType
    case unexpectedTuple
    case unexpectedRecord
    case unexpectedVariant
    case unexpectedList
    case unexpectedInjection
    case missingFields
    case unexpectedFields
    case unexpectedFieldAccess
    case unexpectedTag
    case unexpectedIndex
    case unexpectedLength
    case ambiguosSum
    case ambiguosVariant
    case ambiguosList
    case emptyMatch
    case nonexhaustiveMatch
    case unexpectedPattern
    case duplicateFields
    case duplicateTypeFields
    case duplicateTypeTags
    case incorrectMainArity
    case incorrectArgumentsNumber
    case unexpectedParametersNumber
}

extension TypeCheckError {
    var code: String {
        switch self {
        case .missingMain: "ERROR_MISSING_MAIN"
        case .undefinedVariable: "ERROR_UDEFINED_VARIABLE"
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
        case .emptyMatch: "ERROR_ILLEGAL_EMPTY_MATCHING"
        case .nonexhaustiveMatch: "ERROR_NONEXHAUSTIVE_MATCH_PATTERNS"
        case .unexpectedPattern: "ERROR_UNEXPECTED_PATTERN_FOR_TYPE"
        case .duplicateFields: "ERROR_DUPLICATE_RECORD_FIELDS"
        case .duplicateTypeFields: "ERROR_DUPLICATE_RECORD_TYPE_FIELDS"
        case .duplicateTypeTags: "ERROR_DUPLICATE_VARIANT_TYPE_FIELDS"
        case .incorrectMainArity: "ERROR_INCORRECT_ARITY_OF_MAIN"
        case .incorrectArgumentsNumber: "ERROR_INCORRECT_NUMBER_OF_ARGUMENTS"
        case .unexpectedParametersNumber: "ERROR_UNEXPECTED_NUMBER_OF_PARAMETERS_IN_LAMBDA"
        }
    }
}

extension TypeCheckError {
    var message: String? {
        switch self {
            case .missingMain:
                "main function is missing from the program"
            case .incorrectMainArity: 
                "main function must have one and only one parameter"
            default: nil
        }
    }
}
