slidenumbers: true slide-transition: true

# [fit] Parser Combinators

---

# Self Intro
- Name: Joshua Kaplan
- Interests: 🥨 λ 🍺
- Company: GMO Pepabo
- Service: minne

^ Japan's largest handmade market. We're hosting this event today. We're hiring.

---

# [fit] What are Parser Combinators?

---

- Higher-order function that takes multiple parsers and /combines/ them into a new parser
- CS theory
- Parsec, Haskell

^ Appearing in CS papers 1989, popularized by the Parsec library in Haskell. Parsec uses a range of infix operators to express complex composition in a concise and easy-to-read way. My examples are highly inspired by Point-Free and ObjC.io

---

## In Swift

```swift
struct Parser<A> {
    let run: (inout Substring) throws -> A
}
```

---

## Characteristics

- Monadic
- Composable
- Generic
- Immutable

^ I don't have time to define a monad, but think of it as an abstract concept that accepts similar operations in any of its iterations. Think of map operations on Swift collection, optionals, and Rx streams

---

## Use

```swift
let int = Parser<Int> { input in
    let num = input.prefix(while: { $0.isNumber })
    guard let number = Int(num) else { throw ParserError.IntError.notANumber(num) }

    input.removeFirst(num.count)
    return number
}
```

^ Parse from the left as long as condition is met, then return the remaining substring

---

```swift
func removingLiteral(_ string: String) -> Parser<Void> {
    return Parser<Void> { input in
        guard input.hasPrefix(string) else {
          throw ParserError.StringError.literalNotFound(string[...])
        }
        input.removeFirst(string.count)
    }
}
```

^ removingLiteral just strips away a string literal

---
## Higher order functions

- map
- flatMap (bind, >>=)
- zip

^ Able to define these operations to combine and adjust parsers. map and flatMap change parsers while zip combines parsers

---

```swift
struct Coordinate { let x, y: Int }
let str = "1,2"

let coordinateParser = zip(
  int,
  removingLiteral(","),
  int
).map { x, _, y in Coordinate(x: x, y: y) }

let (coordinate, _) = try coordinateParser.run(str[...])

▿ Coordinate
  - x: 1
  - y: 2
```

^ Here we take the int parser and combine it with the parser returned from removingLiteral

---

```swift
func substring(while predicate: @escaping (Character) -> Bool) -> Parser<Substring> {
    return Parser<Substring> { input in
        let p = input.prefix(while: predicate)
        input.removeFirst(p.count)

        return p
    }
}
```

^ A generalized parser that acts as a component to other parsers

---

## Let's make another parser!

```swift
struct Person { let name: String; let age: Int }
let str = "name: John, age: 90"
```
^ Let's make a parser for this person struct.

---

## Name and age parsers

```swift
let nameParser = zip(
  removingLiteral("name: "),
  substring(while: { $0.isLetter })
).map { _, name in return String(name) }

let ageParser = zip(
  removingLiteral("age: "),
  int
).map { _, age in return age }

```

^ First we make a nameParser, then an ageParser

---

## Person parser

```swift
let personParser = zip(
  nameParser,
  removingLiteral(", "),
  ageParser
).map { name, _, age in return Person(name: name, age: age) }

let (person, _) = try personParser.run(str[...])
▿ Person
  - name: "John"
  - age: 90
```

^ Then combine them using zip to make a Person parser

---

# Comparison

- By hand
- Scanner

^ Not enough time to show you, but generally more work

---

## [fit] Why and when?

^ For apps, maybe useful for parsing phone numbers, emails, etc. Instead, parser combinators are more useful as a tool to study monadic operations and functional programming. Everything we do deals with text!

---

## References

 - https://github.com/pointfreeco/episode-code-samples/tree/master/0064-parser-combinators-pt3
 - https://talk.objc.io/episodes/S01E13-parsing-techniques
 - https://github.com/johnpatrickmorgan/Sparse
 - https://github.com/davedufresne/SwiftParsec
 - https://github.com/thoughtbot/Argo
 - https://github.com/tryswift/TryParsec
