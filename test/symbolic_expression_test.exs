defmodule SymbolicExpressionTest do
  use ExUnit.Case

  doctest SymbolicExpression.Writer
  doctest SymbolicExpression.Parser
  doctest SymbolicExpression.Sigil
  doctest SymbolicExpression.Canonical.Writer
  doctest SymbolicExpression.Canonical.Parser
end
