///|
pub fn LazyBuilder::run_force[A](self : LazyBuilder[A]) -> A {
  self.run().force()
}

///|
pub fn LazyBuilder::run[A](self : LazyBuilder[A]) -> Lazy[A] {
  Lazy::fix(self._)
}

///|
pub fn LazyBuilder::inherit[A, B](
  self : LazyBuilder[A],
  f : (A) -> B,
  g : (B) -> A
) -> LazyBuilder[B] {
  let ab = fn(a : Lazy[A]) { a.map(f) }
  let ba = fn(b : Lazy[B]) { b.map(g) }
  let aa = self._
  @fun.compose(ab, @fun.compose(aa, ba))
}

///|
pub fn LazyBuilder::map[A](
  self : LazyBuilder[A],
  f : (A) -> A
) -> LazyBuilder[A] {
  let aa = fn(a : Lazy[A]) { a.map(f) }
  @fun.compose(aa, self._)
}

///|
pub fn LazyBuilder::new[A](f : (Lazy[A]) -> A) -> LazyBuilder[A] {
  fn(self : Lazy[A]) { Lazy::from_val(f(self)) }
}
