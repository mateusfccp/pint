<img src="https://mateusfccp.me/pinto/images/logo.png" width="300">

[![GitHub License](https://img.shields.io/github/license/mateusfccp/pinto)](./LICENSE)
[![Pub Version](https://img.shields.io/pub/v/pinto)](https://pub.dev/packages/pinto)
[![Discord Shield](https://img.shields.io/discord/1286023882515677236)](https://discord.gg/Y9cWqCUCCG)

The pint° (/pĩntʊ/) programming language.

> [!WARNING]
> The pint° programming language is still in very early development stage, and
is not recommended for use in production software. Use at your own risk.

The pint° programming language is a language that compiles to Dart.

It has the following objectives:

- Have seamless interoperability with Dart;
- Consider Flutter as first-class;
- Generate reasonably readable and efficient Dart code;
- Be terser and more expressive than Dart;
- Provide a powerful macro system with great ergonomy.

```haskell
import @async

let name = "pint°"
let isTheBestLanguage = true

type Complex(T) = Complex(
  [Unknown] listOfUnknownElements,
  [T] listOfT,
  {T} set,
  {T: T} map,
  T? maybeT,
  Future(T) futureOfT,
  int aSimpleInt,
  {{T?} : [Future(T)]} aMonster
)

let main _ =
  print "Hello, world!"

```

You can get started with the language by reading
[the documentation](https://mateusfccp.me/pinto/docs).
