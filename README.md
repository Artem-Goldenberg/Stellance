# Stellance

Learning project, a type checker for the language called [Stella](https://fizruk.github.io/stella/) written in Swift.

To parse and work with stella code, I use my own [SwiftStella](https://github.com/Artem-Goldenberg/SwiftStella) parsing 
library for Swift.

Also I use a common [repository](https://github.com/Zelourses/stella-tests) with stella tests.

## Install

To install and run the project you need to have [Swift](https://www.swift.org/install) version 6.0 or higher. 
To check use
```
swift --version
```

To clone the repository, use
```
git clone --recurse-submodules "https://github.com/Artem-Goldenberg/Stellance.git"
```
> If you've already cloned without the `--recurse-submodules`, 
  use `git submodule init` and then `git submodule update` commands 
  to download submodule dependencies.

After that, you can run an executable using something like
```
cat <stella-source> | swift run
```

It will read stella source code from the standard input and print issues to the standard output and standard error.
If the provided program type checks fine, the type checker will finish with 0 return code.

## File Structure

- Files in [SyntaxCheck](Sources/Stellance/SyntaxCheck) folder checks that the program doesn't use any extensions which weren't included
- [TypeChecking.swift](Sources/Stellance/TypeChecking.swift) recursive function to check expressions when expected type is known
- [TypeInference.swift](Sources/Stellance/TypeInference.swift) recursive function to infer type for expression
- [PatternMatching.swift](Sources/Stellance/PatternMatching.swift) recursive function to bind the pattern to a type and update the context
- [Errors.swift](Sources/Stellance/Errors.swift) all supported errors and error messages
- [Model.swift](Sources/Stellance/Model.swift) some important structures including an enum of all the supported extensions

## Stages

- Implementation for Stage 1 should support all extesions (extra ones as well) specified in the pdf task for this stage

- Stage 2: All extensions specified in the .pdf should work as well


