///|
type Name = String

///|
enum Raw {
  RVar(Name)
  RApp(Raw, Raw)
  RLam(Name, Raw)
  RSrcPos(SourcePos, Raw)
}

///|
enum Tm {
  Ix(Int)
  Lam(Name, Tm)
  App(Tm, Tm)
}

///|
impl Show for Raw with output(self, logger) {
  match self {
    RLam(x, t) => {
      logger.write_string("(\u03bb ")
      logger.write_string(x)
      logger.write_string(".")
      logger.write_object(t)
      logger.write_char(')')
    }
    RApp(t, u) => {
      logger.write_char('(')
      logger.write_object(t)
      logger.write_char(' ')
      logger.write_object(u)
      logger.write_char(')')
    }
    RVar(x) => logger.write_string(x)
    RSrcPos(_, e) => logger.write_object(e)
  }
}

///|
using @list {cons, empty}

///|
impl Show for Tm with output(self, logger) {
  fn dfs(root : Tm, ns : @list.List[Name]) {
    match root {
      App(t, u) => {
        logger.write_char('(')
        dfs(t, ns)
        logger.write_char(' ')
        dfs(u, ns)
        logger.write_char(')')
      }
      Lam(x, t) => {
        logger.write_string("(\u03bb ")
        logger.write_string(x)
        logger.write_string(".")
        dfs(t, cons(x, ns))
        logger.write_char(')')
      }
      Ix(ix) => {
        let name = ns.nth(ix).unwrap()
        logger.write_string(name)
      }
    }
  }

  dfs(self, @list.empty())
}

///|
let parser : Parser[Raw] = {
  let buffer = StringBuilder::new(size_hint=40)
  let name = (digit | alphabetic)
    .many_each(fn(x) { buffer.write_char(x) })
    .map(fn(_) {
      let res = buffer.to_string()
      buffer.reset()
      res
    })
    .label("name")
  let var_ = name.map(RVar(_))
  letrec lam = fn(input : Input) -> (Raw, Input) raise ParseError {
    let fun = string("fun").discard_spaces()
    let x = name.discard_spaces()
    let t = discard_spaces(expr)
    let lam = fun.discard_left(x.bind(x => t.map(t => RLam(x, t))))
    lam.round_bracket()(input)
  }
  and app = fn(input : Input) -> (Raw, Input) raise ParseError {
    let t = discard_spaces(expr)
    let u = discard_spaces(expr)
    let app = t.bind(t => u.map(u => RApp(t, u)))
    app.round_bracket()(input)
  }
  and expr = fn(input : Input) -> (Raw, Input) raise ParseError {
    let expr = (lam : Parser[_]) | app | var_
    expr.label("expr").map_srcpos(RSrcPos(_, _))(input)
  }

  discard_right(expr, eof(' '))
}

///|
test "parse" {
  inspect(parser.run(input("(fun x x)")), content="(λ x.x)")
  inspect(parser.run(input("(fun x (fun y y))")), content="(λ x.(λ y.y))")
  inspect(parser.run(input("(x x)")), content="(x x)")
}

///|
type Env = @list.List[Val]

///|
enum Closure {
  Closure(Env, Tm)
}

///|
enum Val {
  VLvl(Int)
  VApp(Val, Val)
  VLam(Name, Closure)
}

///|
fn Closure::app(self : Closure, u : Val) -> Val {
  let Closure(env, t) = self
  t.eval(cons(u, env))
}

///|
suberror ScopeError {
  ScopeError(SourcePos, String, @list.List[String])
}

///|
impl Show for ScopeError with output(self, logger) {
  let ScopeError({ row, col }, x, ctx) = self
  logger.write_string("ScopeError: L\{row}:\{col}: \{x} not found in ")
  logger.write_string("[")
  match ctx.rev() {
    Empty => ()
    More(x, tail~) => {
      logger.write_string(x)
      for x in tail {
        logger.write_string(", ")
        logger.write_string(x)
      }
    }
  }
  logger.write_string("]")
}

///|
fn Tm::eval(self : Tm, env : Env) -> Val {
  match self {
    App(t, u) =>
      match (t.eval(env), u.eval(env)) {
        (VLam(_, t), u) => t.app(u)
        (t, u) => VApp(t, u)
      }
    Lam(x, t) => VLam(x, Closure(env, t))
    Ix(x) => env.nth(x).unwrap()
  }
}

///|
fn lvl_to_ix(len : Int, ix : Int) -> Int {
  len - ix - 1
}

///|
fn Val::quote(self : Val, len : Int) -> Tm {
  match self {
    VApp(t, u) => {
      let f = t.quote(len)
      let x = u.quote(len)
      App(f, x)
    }
    VLvl(x) => Ix(lvl_to_ix(len, x))
    VLam(x, t) => {
      let body = t.app(VLvl(len))
      Lam(x, body.quote(len + 1))
    }
  }
}

///|
fn Tm::nf(self : Tm, env : Env) -> Tm {
  let v = self.eval(env)
  let len = env.length()
  v.quote(len)
}

///|
fn Raw::to_tm(self : Raw) -> Tm raise {
  fn dfs(raw : Raw, ns : @list.List[Name], pos : SourcePos) -> Tm raise {
    match raw {
      RLam(x, t) => Lam(x, dfs(t, cons(x, ns), pos))
      RApp(t, u) => App(dfs(t, ns, pos), dfs(u, ns, pos))
      RVar(name) =>
        Ix(
          ns
          .find_index(fn(x) { x == name })
          .unwrap_or_error(ScopeError(pos, name, ns)),
        )
      RSrcPos(pos, e) => dfs(e, ns, pos)
    }
  }

  dfs(self, empty(), SourcePos::{ row: 0, col: 0 })
}

///|
test "chunch" {
  // raw
  let five = parser.run(input("(fun f (fun x (f (f (f (f (f x)))))))"))
  inspect(five, content="(λ f.(λ x.(f (f (f (f (f x)))))))")
  let add = parser.run(
    input("(fun m (fun n (fun f (fun x ((m f) ((n f) x))))))"),
  )
  inspect(add, content="(λ m.(λ n.(λ f.(λ x.((m f) ((n f) x))))))")
  let mul = parser.run(input("(fun m (fun n (fun f (m (n f)))))"))
  inspect(mul, content="(λ m.(λ n.(λ f.(m (n f)))))")
  let zero = parser.run(input("(fun f (fun x x))"))
  inspect(zero, content="(λ f.(λ x.x))")
  let succ = parser.run(input("(fun n (fun f (fun x (f ((n f) x)))))"))
  inspect(succ, content="(λ n.(λ f.(λ x.(f ((n f) x)))))")
  // tm 
  let five = five.to_tm()
  let add = add.to_tm()
  let mul = mul.to_tm()
  let ten = App(App(add, five), five).nf(empty())
  inspect(
    ten,
    content="(λ f.(λ x.(f (f (f (f (f (f (f (f (f (f x))))))))))))",
  )
  let nat_25 = App(App(mul, five), five).nf(empty())
  inspect(
    nat_25,
    content="(λ f.(λ x.(f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f (f x)))))))))))))))))))))))))))",
  )
}

///|
test "scope error" {
  let e1 = parser.run(input("(fun x y)"))
  inspect(try? e1.to_tm(), content="Err(ScopeError: L0:7: y not found in [x])")
  let e2 = parser.run(input("(fun x (fun y (fun z w)))"))
  inspect(
    try? e2.to_tm(),
    content="Err(ScopeError: L0:21: w not found in [x, y, z])",
  )
}
