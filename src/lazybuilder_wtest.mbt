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
  inspect!(x.1.force(), content="4")
}

///|
test "fix/even odd" {
  struct Nat {
    even : Lazy[(Int) -> Bool]
    odd : Lazy[(Int) -> Bool]
  }
  let nat : LazyBuilder[Nat] = LazyBuilder::new(fn(self : Lazy[Nat]) {
    {
      even: Lazy::new(fn() {
        fn(n) {
          self.force().odd
          .map(fn(odd) { fn(n) { if n == 0 { true } else { odd(n - 1) } } })
          .force()(n)
        }
      }),
      odd: Lazy::new(fn() {
        self.force().even
        .map(fn(even) { fn(n) { if n == 0 { false } else { even(n - 1) } } })
        .force()
      }),
    }
  })
  let x = nat._ |> Lazy::fix
  let nat = nat.run_force()
  let even = nat.even.force()
  let odd = nat.odd.force()
  inspect!(
    Int::until(0, 5).map(even),
    content="[true, false, true, false, true]",
  )
  inspect!(
    Int::until(0, 5).map(odd),
    content="[false, true, false, true, false]",
  )
}

///|
test "memo test" (t : @test.T) {
  struct X {
    source : Int
    target : Lazy[String]
  } derive(Show)
  let x : LazyBuilder[X] = LazyBuilder::new(fn(self : Lazy[X]) {
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
  inspect!(
    x,
    content=
      #|{source: 16, target: "10"}
    ,
  )
  inspect!(
    x,
    content=
      #|{source: 16, target: "10"}
    ,
  )
  inspect!(
    x,
    content=
      #|{source: 16, target: "10"}
    ,
  )
  inspect!(
    x,
    content=
      #|{source: 16, target: "10"}
    ,
  )
  inspect!(
    y,
    content=
      #|{source: 256, target: "100"}
    ,
  )
  inspect!(
    y,
    content=
      #|{source: 256, target: "100"}
    ,
  )
  inspect!(
    y,
    content=
      #|{source: 256, target: "100"}
    ,
  )
  inspect!(
    y,
    content=
      #|{source: 256, target: "100"}
    ,
  )
  t.snapshot!(filename="memo_test.txt")
}
