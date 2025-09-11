///|
pub fn[A] LazyBuilder::run_force(self : LazyBuilder[A]) -> A {
  self.run().force()
}

///|
pub fn[A] LazyBuilder::run(self : LazyBuilder[A]) -> Lazy[A] {
  Lazy::fix(self.inner())
}

///|
typealias (A) -> B as Arrow[A, B]

///|
fn[A, B, C] compose(f : Arrow[B, C], g : Arrow[A, B]) -> Arrow[A, C] {
  fn(x) { f(g(x)) }
}

///|
pub fn[A, B] LazyBuilder::inherit_(
  self : LazyBuilder[A],
  f : (A) -> B,
  g : (B) -> A,
) -> LazyBuilder[B] {
  let ab = fn(a : Lazy[A]) { a.map(f) }
  let ba = fn(b : Lazy[B]) { b.map(g) }
  let aa = self.inner()
  compose(ab, compose(aa, ba))
}

///|
pub fn[A] LazyBuilder::map(
  self : LazyBuilder[A],
  f : (A) -> A,
) -> LazyBuilder[A] {
  let aa = fn(a : Lazy[A]) { a.map(f) }
  compose(aa, self.inner())
}

///|
pub fn[A] LazyBuilder::new(f : (Lazy[A]) -> A) -> LazyBuilder[A] {
  fn(self : Lazy[A]) { Lazy::from_val(f(self)) }
}
