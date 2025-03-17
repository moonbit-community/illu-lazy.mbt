///|
test (t : @test.T) {
  struct ComponentRepr {
    text : String
    html : Lazy[String]
  }
  type Component LazyRec[ComponentRepr]
  fn new() -> Component {
    LazyRec::new(fn(self : Lazy[ComponentRepr]) {
      {
        text: "",
        html: Lazy::new(fn() {
          let html = "<div>\{self.force().text}<div/>"
          t.writeln("render: \{html}")
          html
        }),
      }
    })
  }
  fn modify_text(self : Component, f : (String) -> String) -> Unit {
    self._.modify(fn (self) { 
      {
        text : f(self.text),
        html : self.html
      }
    })
  }

  fn html(self : Component) -> String {
    self._.get(fn(self) { self.html.force() })
  }

  let c = new()
  modify_text(c,fn(_) { "hello world"})
  inspect!(html(c), content="<div>hello world<div/>")
  inspect!(html(c), content="<div>hello world<div/>")
  inspect!(html(c), content="<div>hello world<div/>")
  inspect!(html(c), content="<div>hello world<div/>")
  modify_text(c,fn(x) { x + "!" })
  inspect!(html(c), content="<div>hello world!<div/>")
  inspect!(html(c), content="<div>hello world!<div/>")
  inspect!(html(c), content="<div>hello world!<div/>")
  inspect!(html(c), content="<div>hello world!<div/>")
  t.snapshot!(filename="component.txt")

}
