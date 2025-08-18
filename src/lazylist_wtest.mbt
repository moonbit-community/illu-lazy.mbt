///|
priv enum List[A] {
  Nil
  Cons(A, Lazy[List[A]])
}

///|
let counter : Ref[Int] = Ref::new(0)

///|
fn[A] List::reverse_append(self : List[A], other : List[A]) -> List[A] {
  let mut acc = other
  loop self {
    Nil => ()
    Cons(x, xs) => {
      acc = Cons(x, Lazy::from_val(acc))
      continue xs.force()
    }
  }
  acc
}

///|
fn[A] List::reverse(self : List[A]) -> List[A] {
  self.reverse_append(Nil)
}

///|
fn[A, B, C] List::zipWith(
  self : List[A],
  other : List[B],
  f : (A, B) -> C,
) -> List[C] {
  match (self, other) {
    (Nil, _) => Nil
    (_, Nil) => Nil
    (Cons(x, xs), Cons(y, ys)) =>
      Cons(f(x, y), xs.bind(fn(xs) { ys.map(fn(ys) { xs.zipWith(ys, f) }) }))
  }
}

///|
fn[A] List::take(self : List[A], n : Int) -> List[A] {
  let mut acc = Nil
  let mut n = n
  loop self {
    Nil => ()
    Cons(_) if n <= 0 => ()
    Cons(x, xs) => {
      n -= 1
      acc = Cons(x, Lazy::from_val(acc))
      continue xs.force()
    }
  }
  acc.reverse()
}

///|
fn[A] List::_nth(self : List[A], n : Int) -> A {
  let mut n = n
  let mut res = None
  loop self {
    Nil => ()
    Cons(x, _) if n == 0 => res = Some(x)
    Cons(_, xs) => {
      n -= 1
      continue xs.force()
    }
  }
  res.unwrap()
}

///|
fn[A] List::tail(self : List[A]) -> List[A] {
  match self {
    Nil => Nil
    Cons(_, xs) => xs.force()
  }
}

///|
impl[A : Show] Show for List[A] with output(self, logger) {
  logger.write_char('[')
  loop self {
    Nil => ()
    Cons(x, xs) => {
      x.output(logger)
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
      0,
      Lazy::from_val(
        Cons(
          1,
          self.map(fn(self) {
            counter.update(fn(x) { x + 1 })
            self.zipWith(self.tail(), add)
          }),
        ),
      ),
    )
  })
  let fibs = fibs_rec.get(fn(x) { x })
  inspect(
    fibs.take(20),
    content="[0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,]",
  )
  inspect(
    fibs.take(20),
    content="[0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,]",
  )
  let fibs = fibs_rec.get(fn(x) { x })
  inspect(
    fibs.take(20),
    content="[0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,]",
  )
  inspect(counter, content="{val: 19}")
}
