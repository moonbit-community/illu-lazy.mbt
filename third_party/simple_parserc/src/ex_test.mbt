///|
fn input(chars : StringView) -> Input {
  Input::new(chars)
}

///|
test "foldr/none" {
  let input = Input::new("123456")
  let integer = foldr(
    digit,
    pure(0),
    pure((acc, x) => acc * 10 + (Char::to_int(x) - '0'.to_int())),
  )
  inspect(integer.run(input), content="654321")
}

///|
test "foldr/separator" {
  let input = Input::new("1_2_3_4_5_6")
  let integer = foldr(
    digit,
    map(digit, x => Char::to_int(x) - '0'),
    char('_').discard_left(
      pure((acc, x) => acc * 10 + (Char::to_int(x) - '0'.to_int())),
    ),
  )
  inspect(integer.run(input), content="654321")
}

///|
test "foldl/none" {
  let input = Input::new("123456")
  let integer = foldl(
    digit,
    pure(0),
    pure((acc, x) => acc * 10 + (Char::to_int(x) - '0'.to_int())),
  )
  inspect(integer.run(input), content="123456")
}

///|
test "foldl/separator" {
  let input = Input::new("1_2_3_4_5_6")
  let integer = foldl(
    digit,
    map(digit, x => Char::to_int(x) - '0'),
    char('_').discard_left(pure((acc, x) => acc * 10 + (Char::to_int(x) - '0'))),
  )
  inspect(integer.run(input), content="123456")
}

///|
test "calculator" {
  let input = Input::new("123456")
  let integer = foldl(
    digit,
    pure(0),
    pure((acc, x) => acc * 10 + (Char::to_int(x) - '0'.to_int())),
  )
  inspect(integer.run(input), content="123456")
  let add = char('+').discard_left(pure(Int::add))
  let sub = char('-').discard_left(pure(Int::sub))
  let mul = char('*').discard_left(pure(Int::mul))
  let div = char('/').discard_left(pure(Int::div))
  letrec expr = fn(input) -> (Int, Input) raise ParseError {
    foldl1(term, add | sub)(input)
  }
  and term = fn(input) -> (Int, Input) raise ParseError {
    foldl1(factor, mul | div)(input)
  }
  and factor = fn(input) -> (Int, Input) raise ParseError {
    (Parser::round_bracket(expr) | integer)(input)
  }

  let input = Input::new("(1+2)*3")
  let expr : Parser[Int] = expr
  inspect(expr.run(input), content="9")
  inspect(expr.run(Input::new("3*3+4*4")), content="25")
  let buf = StringBuilder::new(size_hint=100_000 * 5)
  buf.write_char('1')
  for i in 0..<100_000 {
    buf.write_char('+')
    buf.write_char('1')
  }
  let input = Input::new(buf.to_string())
  inspect(expr.run(input), content="100001")
}

///|
test "or" {
  let x = char('x')
  let y = char('y')
  let parse = (x | y) |> label("x or y")
  let input = Input::new("x")
  inspect(
    try? parse(input),
    content=(
      #|Ok(('x', {chars: "", row: 0, col: 1}))
    ),
  )
  inspect(
    try? parse(Input::new("_")),
    content=(
      #|Err(
      #|Parse Error:0:0:
      #|    x or y is expected
      #|    y is expected
      #|)
    ),
  )
}

///|
test "error" {
  let parse = char('x')
  let input = Input::new("_")
  inspect(
    try? parse(input),
    content=(
      #|Err(
      #|Parse Error:0:0:
      #|    x is expected
      #|)
    ),
  )
  inspect(
    try? label(parse, "?")(input),
    content=(
      #|Err(
      #|Parse Error:0:0:
      #|    ? is expected
      #|    x is expected
      #|)
    ),
  )
}

///|
test "between" {
  let parser = char('_').round_bracket()
  inspect(parser.run(input("(_)")), content="_")
}

///|
test "digit" {
  inspect(try? digit.run(input("1")), content="Ok('1')")
  inspect(
    try? digit.run(input("_")),
    content=(
      #|Err(
      #|Parse Error:0:0:
      #|    digit is expected
      #|)
    ),
  )
}

///|
test "space" {
  inspect(try? space.run(input(" ")), content="Ok(' ')")
  inspect(
    try? space.run(input("_")),
    content=(
      #|Err(
      #|Parse Error:0:0:
      #|    space is expected
      #|)
    ),
  )
}

///|
test "alphabetic" {
  inspect(try? alphabetic.run(input("a")), content="Ok('a')")
  inspect(
    try? alphabetic.run(input("_")),
    content=(
      #|Err(
      #|Parse Error:0:0:
      #|    alphabetic is expected
      #|)
    ),
  )
}

///|
test "any" {
  inspect(try? any.run(input("a")), content="Ok('a')")
  inspect(try? any.run(input("_")), content="Ok('_')")
}

///|
test "space1" {
  inspect(try? space1.run(input("  ")), content="Ok(' ')")
  inspect(
    try? space1.run(input("")),
    content=(
      #|Err(
      #|Parse Error:0:0:
      #|    space1 is expected
      #|    space is expected
      #|)
    ),
  )
}

///|
test "spaces" {
  inspect(try? spaces.run(input("  ")), content="Ok(' ')")
  inspect(try? spaces.run(input("")), content="Ok(' ')")
}

///|
test "pure" {
  inspect(try? pure(1).run(input("")), content="Ok(1)")
}

///|
test "between/spaces" {
  let x = pure(0).round_bracket()
  inspect(x.run(input("()")), content="0")
  inspect(x.run(input(" ()")), content="0")
  inspect(x.run(input("() ")), content="0")
  inspect(x.run(input("( )")), content="0")
  inspect(x.run(input(" ( ) ")), content="0")
}

///|
test "label" {
  let rb = char(')').label("lambda").label("expr")
  inspect(
    try? rb.run(input("")),
    content=(
      #|Err(
      #|Parse Error:0:0:
      #|    expr is expected
      #|    lambda is expected
      #|    ) is expected
      #|)
    ),
  )
}

///|
test "SourcePos::compare" {
  fn srcpos(row, col) {
    SourcePos::{ row, col }
  }

  inspect(srcpos(0, 1) < srcpos(0, 2), content="true")
  inspect(srcpos(1, 0) > srcpos(0, 2), content="true")
}

///|
test "branch" {
  let x = char('x')
  let y = char('y')
  let fst = x
    .label("x1")
    .discard_left(x.label("x2"))
    .discard_left(x.label("x3"))
  let snd = x.label("x1").discard_left(y.label("y2"))
  let s = input("xx")
  inspect(
    try? (fst | snd).run(s),
    content=(
      #|Err(
      #|Parse Error:0:2:
      #|    x3 is expected
      #|    x is expected
      #|)
    ),
  )
}
