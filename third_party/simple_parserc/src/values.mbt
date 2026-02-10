///|
pub let digit : Parser[Char] = satisfy(Char::is_ascii_digit, label="digit")

///|
pub let space : Parser[Char] = satisfy(Char::is_ascii_whitespace, label="space")

///|
pub let alphabetic : Parser[Char] = satisfy(
  Char::is_ascii_alphabetic,
  label="alphabetic",
)

///|
pub let any : Parser[Char] = satisfy(_ => true, label="any character")

///|
pub let space1 : Parser[Char] = space.foldl1(pure((_, y) => y)).label("space1")

///|
pub let spaces : Parser[Char] = (space1 | pure(' ')).label("spaces")
