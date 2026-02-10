# illusory0x0/simple_parserc



## Primitive combinators

* `|`
  * `lor` `or`
* `label`


## Monadic combinators

* Monad 
  * `bind`
  * `pure` 
  * `map`

* helper function
  * `map_srcpos`
  * `discard_left`
  * `discard_right`


## Folding 

* `foldl`
* `foldl1`
* `foldr`
* `foldr1`
* `many`
* `many_each`

## Derivatives of primitive combinators

* `satisfy`
* `char`
* `one_of`
* `none_of`
* `string`
* `eof`

## `satisfy` helpler function 

* `digit`
* `space`
* `alphabetic`
* `any`
* `space1`
* `spaces`

## Surrounding

* `between`
* `round_bracket`
* `square_bracket`
* `curly_bracket`

## Reference

[megaparsec](https://hackage.haskell.org/package/megaparsec)

[opal](https://github.com/pyrocat101/opal)