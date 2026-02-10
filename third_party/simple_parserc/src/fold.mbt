///|
#as_free_fn
pub fn[A, B] Parser::foldl(
  x : Parser[A],
  z : Parser[B],
  f : Parser[(B, A) -> B],
) -> Parser[B] {
  fn(input) {
    let (z, zr) = z(input)
    let mut rest = zr
    let mut acc = z
    while (try? f(rest)) is Ok((f, fr)) && (try? x(fr)) is Ok((x, xr)) {
      acc = f(acc, x)
      rest = xr
    }
    (acc, rest)
  }
}

///|
#as_free_fn
pub fn[A, B] Parser::foldr(
  x : Parser[A],
  z : Parser[B],
  f : Parser[(B, A) -> B],
) -> Parser[B] {
  fn(input) {
    let buffer = []
    let mut rest = input
    while (try? x(rest)) is Ok((x, xr)) && (try? f(xr)) is Ok((f, fr)) {
      buffer.push((x, f))
      rest = fr
    }
    let (z, rest) = z(rest)
    let mut acc = z
    for e in buffer.rev_iter() {
      let (x, f) = e
      acc = f(acc, x)
    }
    (acc, rest)
  }
}

///|
#as_free_fn
pub fn[A] Parser::foldr1(x : Parser[A], f : Parser[(A, A) -> A]) -> Parser[A] {
  foldr(x, x, f)
}

///|
#as_free_fn
pub fn[A] Parser::foldl1(x : Parser[A], f : Parser[(A, A) -> A]) -> Parser[A] {
  foldl(x, x, f)
}

///|
#as_free_fn
pub fn[A] Parser::many_each(x : Parser[A], f : (A) -> Unit) -> Parser[Unit] {
  fn(input) {
    let r = x(input)
    f(r.0)
    let mut rest = r.1
    while (try? x(rest)) is Ok((v, vr)) {
      f(v)
      rest = vr
    }
    ((), rest)
  }
}

///|
#as_free_fn
pub fn[A] Parser::many(self : Parser[A]) -> Parser[Array[A]] {
  self.foldl(
    pure([]),
    pure(fn(acc : Array[A], x) {
      acc.push(x)
      acc
    }),
  )
}
