///|
pub fn Lazy::force[A](self : Lazy[A]) -> A {
  match self.repr {
    Value(val) => val
    Thunk(fun) => {
      let val = fun()
      self.repr = Value(val)
      val
    }
  }
}

///|
fn Lazy::from_val[A](val : A) -> Lazy[A] {
  { repr: Value(val) }
}

///|
fn Lazy::from_fun[A](fun : () -> A) -> Lazy[A] {
  { repr: Thunk(fun) }
}

///|
pub fn Lazy::new[A](fun : () -> A) -> Lazy[A] {
  Lazy::from_fun(fun)
}

///|
pub fn Lazy::map[A, B](self : Lazy[A], f : (A) -> B) -> Lazy[B] {
  match self.repr {
    Value(val) => Lazy::from_val(f(val))
    Thunk(fun) => Lazy::from_fun(fn() { f(fun()) })
  }
}

///|
pub fn Lazy::fix[A](f : (Lazy[A]) -> Lazy[A]) -> Lazy[A] {
  fn fun() -> A {
    f(Lazy::from_fun(fun)).force()
  }

  Lazy::from_fun(fun)
}

///|
pub fn Lazy::join[A](self : Lazy[Lazy[A]]) -> Lazy[A] {
  match self.repr {
    Value(val) => val
    Thunk(fun) => fun()
  }
}

///|
pub fn Lazy::bind[A, B](self : Lazy[A], f : (A) -> Lazy[B]) -> Lazy[B] {
  match self.repr {
    Value(val) => f(val)
    Thunk(fun) => f(fun())
  }
}


pub impl[A : Show] Show for Lazy[A] with output(self,logger) {
  self.force().output(logger)
}