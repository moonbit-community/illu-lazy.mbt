///|
#as_free_fn
pub fn[A, B, C] Parser::between(
  self : Parser[A],
  open~ : Parser[B],
  close~ : Parser[C],
) -> Parser[A] {
  open
  .discard_spaces()
  .discard_left(self.discard_spaces())
  .discard_right(close)
  .discard_spaces()
}

///|
#as_free_fn
pub fn[A] Parser::round_bracket(self : Parser[A]) -> Parser[A] {
  self.between(open=char('('), close=char(')'))
}

///|
#as_free_fn
pub fn[A] Parser::square_bracket(self : Parser[A]) -> Parser[A] {
  self.between(open=char('['), close=char(']'))
}

///|
#as_free_fn
pub fn[A] Parser::curly_bracket(self : Parser[A]) -> Parser[A] {
  self.between(open=char('{'), close=char('}'))
}
