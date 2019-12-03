import Foundation

/*
 Main refs:
 - https://github.com/pointfreeco/episode-code-samples/tree/master/0064-parser-combinators-pt3
 - https://talk.objc.io/episodes/S01E13-parsing-techniques
 - https://github.com/johnpatrickmorgan/Sparse
 - https://github.com/davedufresne/SwiftParsec
 - https://github.com/thoughtbot/Argo
 - https://github.com/tryswift/TryParsec
 */

func curry<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
    return { a in { b in f(a, b) } }
}

func curry<A, B, C, D>(_ f: @escaping (A, B, C) -> D) -> (A) -> (B) -> (C) -> D {
    return { a in { b in { c in f(a, b, c) } } }
}

enum ParserError: Error {
    case never
    case unexpectedEnd
    // Error type for each primitive parser

    enum IntError: Error {
        case notANumber(Substring)
    }

    enum StringError: Error {
        case literalNotFound(Substring)
    }

    enum CharError: Error {
        case emptyInput
    }
}

struct Parser<A> {
    let run: (inout Substring) throws -> A
}

extension Parser {
    static var never: Parser {
        return Parser { _ in throw ParserError.never }
    }

    func run(_ str: String) throws -> (match: A, rest: Substring) {
        var input = str[...]
        let match = try self.run(&input)
        return (match, input)
    }

    func or(_ others: Parser<A>...) throws -> Parser<A> {
        return Parser<A> { input in
            do {
                return try self.run(&input)
            } catch {
                for (index, other) in others.enumerated() {
                    if index == others.endIndex - 1 {
                        return try other.run(&input)
                    } else {
                        do { return try other.run(&input) }
                    }
                }
            }
            throw ParserError.unexpectedEnd
        }
    }

    func map<B>(_ f: @escaping (A) throws -> B) rethrows -> Parser<B> {
        return Parser<B> { input throws -> B in
            try f(self.run(&input))
        }
    }

    func flatMap<B>(_ f: @escaping (A) throws -> Parser<B>) rethrows -> Parser<B> {
        return Parser<B> { input throws -> B in
            let original = input
            let matchA = try self.run(&input)
            let parserB = try f(matchA)
            do {
                let matchB = try parserB.run(&input)
                return matchB

            } catch {
                // return to initial val upon failure
                input = original
                throw error
            }
        }
    }

}

/// zip2
func zip<A, B>(_ a: Parser<A>, _ b: Parser<B>) -> Parser<(A, B)> {
    return Parser<(A, B)> { input throws -> (A, B) in
        let original = input
        let matchA = try a.run(&input)
        // TODO: check timing for string chomping behavior
        do {
            let matchB = try b.run(&input)
            return (matchA, matchB)

        } catch {
            input = original
            throw error
        }
    }
}

/// zip3
func zip<A, B, C>(
    _ a: Parser<A>,
    _ b: Parser<B>,
    _ c: Parser<C>
    ) -> Parser<(A, B, C)> {
    return zip(a, zip(b, c))
        .map { a, bc in (a, bc.0, bc.1) }
}

func always<A>(_ a: A) -> Parser<A> {
    return Parser<A> { _ in a }
}

let char = Parser<Character> { input in
    guard let c = input.first else { throw ParserError.CharError.emptyInput }
    return c
}

func substring(while predicate: @escaping (Character) -> Bool) -> Parser<Substring> {
    return Parser<Substring> { input in
        let p = input.prefix(while: predicate)
        input.removeFirst(p.count)

        return p
    }
}

let int = Parser<Int> { input in
    let num = input.prefix(while: { $0.isNumber })
    guard let number = Int(num) else { throw ParserError.IntError.notANumber(num) }

    input.removeFirst(num.count)
    return number
}

func removingLiteral(_ string: String) -> Parser<Void> {
    return Parser<Void> { input in
        guard input.hasPrefix(string) else { throw ParserError.StringError.literalNotFound(string[...]) }
        input.removeFirst(string.count)
    }
}

let trueBool: Parser<Bool> = try removingLiteral("true").or(removingLiteral("True")).map { _ in
    return true
}

let falseBool: Parser<Bool> = try removingLiteral("false").or(removingLiteral("False")).map { _ in
    return false
}

let bool: Parser<Bool> = try trueBool.or(falseBool)

let str = "name: John, age: 90"

struct Person { let name: String; let age: Int }

let nameParser = zip(removingLiteral("name: "), substring(while: { $0.isLetter })).map { _, name in return String(name) }
let ageParser = zip(removingLiteral("age: "), int).map { _, age in return age }
let personParser = zip(nameParser, removingLiteral(", "), ageParser).map { name, _, age in return Person(name: name, age: age) }
let (person, _) = try personParser.run(str)
dump(person)
