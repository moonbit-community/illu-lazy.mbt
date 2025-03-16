///|
test "fix/const" {
  let x = Lazy::fix(fn(_) { Lazy::from_val(0) }).force()
  inspect!(x, content="0")
}
