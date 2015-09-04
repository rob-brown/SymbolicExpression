# SymbolicExpression

## Summary

`SymbolicExpression` is a lightweight library for parsing and writing s-expressions.

## Example

S-expressions can be parsed in one of two ways. First is to use the parser directly.

```elixir
SymbolicExpression.Parser.parse """
(a
  (b "test"
    (c 1)
    (c 2.0)))
"""
# => {:ok, [:a, [:b, "test", [:c, 1], [:c, 2.0]]]}
```

The second way is to use the custom sigil provided.

```elixir
import SymbolicExpression.Parser.Sigil
~p"""
(a
  (b "test"
    (c 1)
    (c 2.0)))
"""
# => [:a, [:b, "test", [:c, 1], [:c, 2.0]]]
```

Be aware that the sigil will raise an exception if given an invalid s-expression. 
