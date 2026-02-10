///|
#as_free_fn
pub fn[A, B] Parser::bind(x : Parser[A], f : (A) -> Parser[B]) -> Parser[B] {
  fn(input) {
    let (v, rest) = x(input)
    f(v)(rest)
  }
}

///|
#as_free_fn
pub fn[A] Parser::pure(x : A) -> Parser[A] {
  fn(input) { (x, input) }
}

///|
#as_free_fn
pub fn[A, B] Parser::map(self : Parser[A], f : (A) -> B) -> Parser[B] {
  self.bind(x => pure(f(x)))
}

///|
#as_free_fn
pub fn[A, B] Parser::map_srcpos(
  self : Parser[A],
  f : (SourcePos, A) -> B,
) -> Parser[B] {
  fn(input) {
    let { row, col, .. } = input
    let (x, input) = self(input)
    (f(SourcePos::{ row, col }, x), input)
  }
}

///|
#as_free_fn
pub fn[A, B] Parser::discard_left(x : Parser[A], y : Parser[B]) -> Parser[B] {
  x.bind(_ => y)
}

///|
#as_free_fn
pub fn[A, B] Parser::discard_right(x : Parser[A], y : Parser[B]) -> Parser[A] {
  x.bind(r => y.bind(_ => pure(r)))
}
