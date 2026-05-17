///|
priv struct Nat {
  even : Lazy[(Int) -> Bool]
  odd : Lazy[(Int) -> Bool]
}

///|
test "fix/rec" {
  let x : LazyBuilder[(Int, Lazy[Int])] = LazyBuilder::new(fn(self) {
    (
      2,
      Lazy::new(fn() {
        let x = self.force().0
        x * x
      }),
    )
  })
  x.run_force() |> ignore
  let x = x.run_force()
  inspect(x.1.force(), content="4")
}

///|
test "fix/even odd" {
  let nat : LazyBuilder[Nat] = LazyBuilder::new(fn(self : Lazy[Nat]) {
    {
      even: Lazy::new(fn() {
        fn(n) {
          self.force().odd
          .map(fn(odd) { if n == 0 { true } else { odd(n - 1) } })
          .force()
        }
      }),
      odd: Lazy::new(fn() {
        fn(n) {
          self.force().even
          .map(fn(even) { if n == 0 { false } else { even(n - 1) } })
          .force()
        }
      }),
    }
  })
  let x = nat.0 |> Lazy::fix
  let nat = nat.run_force()
  let even = nat.even.force()
  let odd = nat.odd.force()
  debug_inspect(
    Int::until(0, 5).map(even).collect(),
    content="[true, false, true, false, true]",
  )
  debug_inspect(
    Int::until(0, 5).map(odd).collect(),
    content="[false, true, false, true, false]",
  )
}

///|
priv struct MemoTestX {
  source : Int
  target : Lazy[String]
}

///|
impl Show for MemoTestX with output(self, logger) {
  let builder = StringBuilder::new()
  builder.write_string("{source: ")
  builder.write_object(self.source)
  builder.write_string(", target: ")
  builder.write_object(self.target)
  builder.write_char('}')
  builder.output(logger)
}

///|
test "memo test" (t : @test.Test) {
  let x : LazyBuilder[MemoTestX] = LazyBuilder::new(fn(self : Lazy[MemoTestX]) {
    {
      source: 16,
      target: Lazy::new(fn() {
        t.writeln("done")
        self.force().source.to_string(radix=16)
      }),
    }
  })
  let y = x.map(fn(self) {
    { source: self.source * self.source, target: self.target }
  })
  let x = x.run_force()
  let y = y.run_force()
  inspect(
    x,
    content=(
      #|{source: 16, target: 10}
    ),
  )
  inspect(
    x,
    content=(
      #|{source: 16, target: 10}
    ),
  )
  inspect(
    x,
    content=(
      #|{source: 16, target: 10}
    ),
  )
  inspect(
    x,
    content=(
      #|{source: 16, target: 10}
    ),
  )
  inspect(
    y,
    content=(
      #|{source: 256, target: 100}
    ),
  )
  inspect(
    y,
    content=(
      #|{source: 256, target: 100}
    ),
  )
  inspect(
    y,
    content=(
      #|{source: 256, target: 100}
    ),
  )
  inspect(
    y,
    content=(
      #|{source: 256, target: 100}
    ),
  )
  t.snapshot(filename="memo_test.txt")
}
