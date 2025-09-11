# illusory0x0/lazy

a lazy library support recursion

## Example

### [component](https://github.com/illusory0x0/lazy.mbt/blob/master/src/component_wtest.mbt)

### [extensible parser](https://github.com/illusory0x0/lazy.mbt/blob/master/src/extensible_parser_wtest.mbt)

This example refer to zhihu blogs [愿你走出半生，归来仍是 Java Parser - 圆角骑士魔理沙的文章 - 知乎](https://zhuanlan.zhihu.com/p/51811022)

Haskell implementation [MarisaKirisame/extensible-parser](https://github.com/MarisaKirisame/extensible-parser)

Haskell2010 implementation [illusory0x0/extensible-parser](https://github.com/illusory0x0/extensible-parser)

Moonbit implementation [illusory0x0/extensible-parser.mbt](https://github.com/illusory0x0/extensible-parser.mbt)

### [even/odd](https://github.com/illusory0x0/lazy.mbt/blob/master/src/lazybuilder_wtest.mbt)

Haskell implementation [gist](https://gist.github.com/illusory0x0/fe4d4aa55ecf47d2cae7c8e5561282b2)

#### Recommaned Reading

[lazy pattern match](https://wiki.haskell.org/Lazy_pattern_match)
[strict pattern match](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/strict.html)

### [lazylist/fibs](https://github.com/illusory0x0/lazy.mbt/blob/master/src/lazylist_wtest.mbt)

Haskell implementation [fibs](https://wiki.haskell.org/The_Fibonacci_sequence)

lazy is not recommaned used for this example, lazy is `call by need` is suitable for some lazy values won't actually be used

GHC is implemented by [Graph Reduction](https://en.wikibooks.org/wiki/Haskell/Graph_reduction), `G-machine` never **Stack Overflow**,
Moonbit hasn't this runtime support, So implement `fibs` use `zipWith` efficiently is impossible.

```haskell
fibs = 0 : 1 : zipWith (+) fibs (tail fibs)
```

