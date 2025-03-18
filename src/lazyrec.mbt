///|
pub fn LazyRec::new[A](f : (Lazy[A]) -> A) -> LazyRec[A] {
  { repr: LazyBuilder::new(f), memo: None }
}

///|
pub fn LazyRec::modify[A](self : LazyRec[A], f : (A) -> A) -> Unit {
  self.repr = self.repr.map(f)
  self.memo = None
}

///|
pub fn LazyRec::get[A, B](self : LazyRec[A], f : (A) -> B) -> B {
  fn aux(lazy) {
    self.memo = Some(lazy)
    lazy.force() |> f
  }

  match self.memo {
    None => aux(self.repr.run())
    Some(lazy) => aux(lazy)
  }
}
