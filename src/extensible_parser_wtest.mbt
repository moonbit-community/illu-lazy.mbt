///|
using @pc {type Parser}

///|
priv struct OriginalParser[Repr] {
  litP : Lazy[Parser[Repr]]
  plusP : Lazy[Parser[Repr]]
  wholeP : Lazy[Parser[Repr]]
}

///|
priv struct ExtendedParser[Repr] {
  litP : Lazy[Parser[Repr]]
  plusP : Lazy[Parser[Repr]]
  varP : Lazy[Parser[Repr]]
  wholeP : Lazy[Parser[Repr]]
}

///|
let intP : @pc.Parser[Int] = @pc.foldl(
  @pc.digit,
  @pc.pure(0),
  @pc.pure((acc, x) => acc * 10 + (Char::to_int(x) - '0'.to_int())),
)

///|
let letterP : Parser[Char] = @pc.alphabetic

///|
let stringP : Parser[String] = {
  let buffer = StringBuilder::new()
  letterP
  .many_each(fn(ch) { buffer.write_char(ch) })
  .map(fn(_) {
    let res = buffer.to_string()
    buffer.reset()
    res
  })
}

///|
let charP = @pc.any

///|
let spaces : @pc.Parser[Char] = @pc.spaces

///|
priv trait AST {
  lit(Int) -> Self
  plus(Self, Self) -> Self
}

///|
priv trait Var {
  var_(String) -> Self
}

///|
priv struct MyString(String)

///|
impl Show for MyString with output(self, logger) {
  self.0.output(logger)
}

///|
impl AST for MyString with lit(self) {
  self.to_string()
}

///|
impl AST for MyString with plus(lhs, rhs) {
  "(\{lhs.0} + \{rhs.0})"
}

///|
impl Var for MyString with var_(self) {
  self
}

///|
fn[Repr : AST] originalParser() -> LazyBuilder[OriginalParser[Repr]] {
  fn(self) {
    Lazy::from_fun(fn() {
      let litP = Lazy::from_val(intP.map(Repr::lit))
      let plusP = Lazy::from_fun(fn() {
        Parser::Parser(fn(input) {
          let plusP = self.force().wholeP.map(fn(wholeP) {
            @pc.between(
              @pc.foldl1(
                wholeP,
                @pc.char('+').discard_left(@pc.pure(Repr::plus)),
              ),
              open=@pc.char('('),
              close=@pc.char(')'),
            )
          })
          plusP.force()(input)
        })
      })
      let wholeP = Lazy::from_fun(fn() {
        Parser::Parser(fn(input) {
          let { litP, plusP, .. } = self.force()
          let wholeP : Lazy[Parser[Repr]] = litP.bind(fn(litP) {
            plusP.map(fn(plusP) { plusP | litP })
          })
          wholeP.force()(input)
        })
      })
      { litP, plusP, wholeP }
    })
  }
}

///|
fn[Repr : AST + Var] extendedParser() -> LazyBuilder[ExtendedParser[Repr]] {
  fn f(self : OriginalParser[Repr]) -> ExtendedParser[Repr] {
    let { litP, plusP, wholeP } = self
    let varP = stringP.map(Var::var_)
    let wholeP = Lazy::new(fn() { varP | wholeP.force() })
    let varP = Lazy::from_val(varP)
    { varP, litP, plusP, wholeP }
  }

  fn g(self : ExtendedParser[Repr]) {
    let { varP, litP, plusP, wholeP } = self
    { litP, plusP, wholeP }
  }

  let originalParser : LazyBuilder[OriginalParser[Repr]] = originalParser()
  originalParser.inherit_(f, g)
}

///|
test "OriginalParser" {
  let parser : LazyBuilder[OriginalParser[MyString]] = originalParser()
  let { litP, plusP, wholeP } = parser.run_force()
  let litP = litP.force()
  let plusP = plusP.force()
  let wholeP = wholeP.force()
  inspect(
    litP.run(@pc.Input::new("123")),
    content=(
      #|"123"
    ),
  )
  inspect(
    plusP.run(@pc.Input::new("(1+2)")),
    content=(
      #|"(1 + 2)"
    ),
  )
  inspect(
    wholeP.run(@pc.Input::new("(1+2)")),
    content=(
      #|"(1 + 2)"
    ),
  )
}

///|
test "ExtendedParser" {
  let parser : LazyBuilder[ExtendedParser[MyString]] = extendedParser()
  let parser = parser.run_force()
  let { varP, litP, plusP, wholeP } = parser
  let litP = litP.force()
  let plusP = plusP.force()
  let wholeP = wholeP.force()
  let varP = varP.force()
  inspect(
    wholeP.run(@pc.Input::new("(1+a)")),
    content=(
      #|"(1 + a)"
    ),
  )
  inspect(
    varP.run(@pc.Input::new("abc")),
    content=(
      #|"abc"
    ),
  )
  inspect(
    wholeP.run(@pc.Input::new("(1+(1+2))")),
    content=(
      #|"(1 + (1 + 2))"
    ),
  )
}
