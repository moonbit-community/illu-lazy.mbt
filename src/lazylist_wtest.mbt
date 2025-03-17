///|
enum List[A] {
  Nil
  Cons(Lazy[A], Lazy[List[A]])
}

///|
let counter : Ref[Int] = Ref::new(0)

///|
fn List::zipWith[A, B, C](
  self : List[A],
  other : List[B],
  f : (A, B) -> C
) -> List[C] {
  match (self, other) {
    (Nil, _) => Nil
    (_, Nil) => Nil
    (Cons(x, xs), Cons(y, ys)) =>
      Cons(
        Lazy::from_fun(fn() { f(x.force(), y.force()) }),
        xs.bind(fn(xs) { ys.map(fn(ys) { xs.zipWith(ys, f) }) }),
      )
  }
}

///|
fn List::take[A](self : List[A], n : Int) -> List[A] {
  match (n, self) {
    (n, _) if n <= 0 => Nil
    (_, Nil) => Nil
    (n, Cons(x, xs)) => Cons(x, xs.map(fn(xs) { xs.take(n - 1) }))
  }
}

///|
fn List::tail[A](self : List[A]) -> List[A] {
  match self {
    Nil => Nil
    Cons(x, xs) => xs.force()
  }
}

///|
pub impl[A : Show] Show for List[A] with output(self, logger) {
  logger.write_char('[')
  loop self {
    Nil => ()
    Cons(x, xs) => {
      x.force().output(logger)
      logger.write_char(',')
      continue xs.force()
    }
  }
  logger.write_char(']')
}

///|
fn add(x : Int, y : Int) -> Int {
  x + y
}

///|
test {
  let fibs_rec : LazyRec[List[Int]] = LazyRec::new(fn(self) {
    Cons(
      Lazy::from_val(0),
      Lazy::from_val(
        Cons(
          Lazy::from_val(1),
          self.map(fn(self) {
            counter.update(fn(x) { x + 1 })
            self.zipWith(self.tail(), add)
          }),
        ),
      ),
    )
  })
  let fibs = fibs_rec.get(fn(x) { x })
  inspect!(
    fibs.take(20),
    content="[0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,]",
  )
  inspect!(
    fibs.take(20),
    content="[0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,]",
  )
  let fibs = fibs_rec.get(fn(x) { x })
  inspect!(
    fibs.take(20),
    content="[0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,]",
  )
  inspect!(counter, content="{val: 19}")
}

///|
test "stack overflow test" {
  let fibs_rec : LazyRec[List[Double]] = LazyRec::new(fn(self) {
    Cons(
      Lazy::from_val(0),
      Lazy::from_val(
        Cons(
          Lazy::from_val(1),
          self.map(fn(self) {
            counter.update(fn(x) { x + 1 })
            self.zipWith(self.tail(), Double::op_add)
          }),
        ),
      ),
    )
  })
  let fibs = fibs_rec.get(fn(x) { x })
  fibs.take(1 << 12).to_string() |> ignore
}
