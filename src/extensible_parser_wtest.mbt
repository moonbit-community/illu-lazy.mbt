///|
typealias Seq[A] = @pc.Seq[A]

///|
typealias Parser[A] = @pc.Parser[Char, A]

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
let intP = @pc.pint

///|
let letterP : Parser[Char] = @pc.pvalue(fn(ch : Char) {
  if ch.is_ascii_alphabetic() {
    Some(ch)
  } else {
    None
  }
})

///|
let stringP : Parser[String] = letterP
  .and_then(letterP.repeat())
  .map(fn {
    (x, xs) => {
      let buf = StringBuilder::new(size_hint=2 * (xs.length() + 1))
      buf.write_char(x)
      for x in xs {
        buf.write_char(x)
      }
      buf.to_string()
    }
  })

///|
let charP = @pc.pchar

///|
let spaces : @pc.Parser[Char, Array[Char]] = @pc.pchar(' ').repeat()

///|
pub fn between[A, B, C](
  content : Parser[A],
  left~ : Parser[B],
  right~ : Parser[C]
) -> Parser[A] {
  left.and_then(content).omit_first().and_then(right).omit_second()
}

///|
pub trait AST {
  lit(Int) -> Self
  plus(Self, Self) -> Self
}

///|
pub trait Var {
  var(String) -> Self
}

///|
pub type MyString String

///|
impl Show for MyString with output(self, logger) {
  self._.output(logger)
}

///|
impl AST for MyString with lit(self) {
  self.to_string()
}

///|
impl AST for MyString with plus(lhs, rhs) {
  "\{lhs._} + \{rhs._}"
}

///|
impl Var for MyString with var(self) {
  self
}

///|
fn originalParser[Repr : AST]() -> LazyBuilder[OriginalParser[Repr]] {
  fn(self) {
    Lazy::from_fun(fn() {
      let litP = Lazy::from_val(intP.map(Repr::lit))
      let plusP = Lazy::from_fun(fn() {
        Parser::new(fn(seq) {
          let plusP = self.force().wholeP.map(fn(wholeP) {
            between(
              wholeP
              .and_then(spaces)
              .omit_second()
              .and_then(charP('+'))
              .omit_second()
              .and_then(spaces)
              .omit_second()
              .and_then(wholeP),
              left=charP('('),
              right=charP(')'),
            ).map(fn { (lhs, rhs) => Repr::plus(lhs, rhs) })
          })
          plusP.force().parse(seq)
        })
      })
      let wholeP = Lazy::from_fun(fn() {
        Parser::new(fn(seq) {
          let { litP, plusP, .. } = self.force()
          let wholeP : Lazy[Parser[Repr]] = litP.bind(fn(litP) {
            plusP.map(fn(plusP) { plusP.or_else(litP) })
          })
          wholeP.force().parse(seq)
        })
      })
      { litP, plusP, wholeP }
    })
  }
}

///|
fn extendedParser[Repr : AST + Var]() -> LazyBuilder[ExtendedParser[Repr]] {
  fn f(self : OriginalParser[Repr]) -> ExtendedParser[Repr] {
    let { litP, plusP, wholeP } = self
    let varP = stringP.map(Repr::var)
    let wholeP = Lazy::new(fn() { wholeP.force().or_else(varP) })
    let varP = Lazy::from_val(varP)
    { varP, litP, plusP, wholeP }
  }

  fn g(self : ExtendedParser[Repr]) {
    let { varP, litP, plusP, wholeP } = self
    { litP, plusP, wholeP }
  }

  let originalParser : LazyBuilder[OriginalParser[Repr]] = originalParser()
  originalParser.inherit(f, g)
}

///|
test "OriginalParser" {
  let parser : LazyBuilder[OriginalParser[MyString]] = originalParser()
  let { litP, plusP, wholeP } = parser.run_force()
  let litP = litP.force()
  let plusP = plusP.force()
  let wholeP = wholeP.force()
  inspect!(
    litP.parse(Seq::from_string("123")),
    content=
      #|Some(("123", ))
    ,
  )
  inspect!(
    plusP.parse(Seq::from_string("(1 + 2)")),
    content=
      #|Some(("1 + 2", ))
    ,
  )
  inspect!(
    wholeP.parse(Seq::from_string("(1 + 2)")),
    content=
      #|Some(("1 + 2", ))
    ,
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
  inspect!(
    wholeP.parse(Seq::from_string("(1 + a)")),
    content=
      #|Some(("1 + a", ))
    ,
  )
  inspect!(
    varP.parse(Seq::from_string("abc")),
    content=
      #|Some(("abc", ))
    ,
  )
  inspect!(
    wholeP.parse(Seq::from_string("(1 + (1 + 2))")),
    content=
      #|Some(("1 + 1 + 2", ))
    ,
  )
}
