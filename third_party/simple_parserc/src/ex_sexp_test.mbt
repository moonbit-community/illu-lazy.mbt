///|
enum Sexp {
  Atom(String)
  List(Array[Sexp])
}

///|
impl Show for Sexp with output(self, logger) {
  match self {
    Atom(s) => logger.write_string(s)
    List(xs) => logger.write_object(xs.iter())
  }
}

///|
test "sexp" {
  let buffer = StringBuilder::new(size_hint=40)
  let atom = (digit | alphabetic | one_of("+-*/"))
    .many_each(fn(x) { buffer.write_char(x) })
    .map(fn(_) {
      let res = Atom(buffer.to_string())
      buffer.reset()
      res
    })
  letrec list = fn(input : Input) -> (Sexp, Input) raise ParseError {
    let expr : Parser[Sexp] = expr
    expr.discard_spaces().many().round_bracket().map(List(_))(input)
  }
  and expr = fn(input : Input) -> (Sexp, Input) raise ParseError {
    Parser::lor(list, atom)(input)
  }

  let expr : Parser[Sexp] = expr
  inspect(atom.run(input("1232")), content="1232")
  inspect(expr.run(input("(1 2 3 4 5 6)")), content="[1, 2, 3, 4, 5, 6]")
  inspect(
    expr.run(input("((1 2) (3 4) (1 (2 (3)))))")),
    content="[[1, 2], [3, 4], [1, [2, [3]]]]",
  )
  inspect(
    expr.run(input("(+ (* 3 3) (* 4 4))")),
    content="[+, [*, 3, 3], [*, 4, 4]]",
  )
}
