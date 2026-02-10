///|
#as_free_fn
pub fn Parser::satisfy(f : (Char) -> Bool, label~ : String) -> Parser[Char] {
  fn(input) {
    let { chars, row, col } = input
    match chars {
      [x, .. chars] if f(x) =>
        if x == '\n' {
          (x, Input::{ chars, row: row + 1, col: 0 })
        } else {
          (x, Input::{ ..input, chars, col: col + 1 })
        }
      _ => raise expect(row~, col~, label)
    }
  }
}

///|
#as_free_fn
pub fn Parser::char(ch : Char) -> Parser[Char] {
  satisfy(c => c == ch, label=ch.to_string())
}

///|
#as_free_fn
pub fn Parser::one_of(xs : String) -> Parser[Char] {
  satisfy(x => String::contains_char(xs, x), label="one of \{xs.iter()}}")
}

///|
#as_free_fn
pub fn Parser::none_of(xs : String) -> Parser[Char] {
  satisfy(
    ch => not(String::contains_char(xs, ch)),
    label="none of \{xs.iter()}}",
  )
}

///|
#as_free_fn
pub fn Parser::string(str : String) -> Parser[String] {
  fn(input) {
    guard not(str.contains_char('\n')) else { panic() }
    let { chars, row, col } = input
    let len = str.length()
    guard chars.length() >= len && chars.view(end_offset=len) == str else {
      raise expect(row~, col~, str)
    }
    (
      str,
      Input::{ ..input, chars: chars.view(start_offset=len), col: col + len },
    )
  }
}

///|
#as_free_fn
pub fn[A] Parser::eof(x : A) -> Parser[A] {
  fn(input) {
    let { chars, row, col } = input
    match chars {
      [] => (x, input)
      _ => raise expect(row~, col~, "eof")
    }
  }
}
