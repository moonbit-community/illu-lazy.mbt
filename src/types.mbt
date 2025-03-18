///|
priv enum Repr[A] {
  Value(A)
  Thunk(() -> A)
}

///|
struct Lazy[A] {
  mut repr : Repr[A]
}

///|
type LazyBuilder[A] (Lazy[A]) -> Lazy[A]

///|
struct LazyRec[A] {
  mut repr : LazyBuilder[A]
  mut memo : Lazy[A]?
}
