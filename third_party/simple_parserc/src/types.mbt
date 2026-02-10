///|
pub(all) struct SourcePos {
  row : Int
  col : Int
} derive(Show, Eq, Compare)

///|
pub(all) struct Input {
  chars : StringView
  row : Int
  col : Int
} derive(Show)

///|
pub(all) suberror ParseError {
  ParseError(SourcePos, @list.List[String])
}

///|
pub(all) struct Parser[A]((Input) -> (A, Input) raise ParseError)

///|
pub impl Show for ParseError with output(self, logger) {
  let ParseError({ row, col }, xs) = self
  logger.write_string("\nParse Error:\{row}:\{col}:\n")
  for msg in xs {
    logger.write_string("    \{msg} is expected\n")
  }
}
