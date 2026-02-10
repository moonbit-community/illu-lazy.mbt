///|
#as_free_fn
pub fn Input::new(chars : StringView) -> Input {
  Input::{ chars, row: 0, col: 0 }
}

///|
#as_free_fn
pub fn[A] Parser::run(self : Parser[A], input : Input) -> A raise ParseError {
  self(input).0
}

///|
#as_free_fn
pub fn[A] Parser::discard_spaces(self : Parser[A]) -> Parser[A] {
  spaces.discard_left(self)
}

///|
#as_free_fn
pub fn[A] Parser::or(x : Parser[A], y : Parser[A]) -> Parser[A] {
  x | y
}

///|
#as_free_fn
pub fn ParseError::expect(row~ : Int, col~ : Int, msg : String) -> ParseError {
  ParseError({ row, col }, @list.List::singleton(msg))
}

///|
pub fn ParseError::source_pos(self : ParseError) -> SourcePos {
  let ParseError(pos, _) = self
  // xs.unsafe_head().0
  pos
}

///|
pub fn ParseError::cons(self : ParseError, x : String) -> ParseError {
  let ParseError(pos, xs) = self
  ParseError(pos, @list.List::cons(x, xs))
}
