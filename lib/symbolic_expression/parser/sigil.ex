defmodule SymbolicExpression.Parser.Sigil do

  @doc """
  Takes an s-expression and parses it. Throws an exception when given an invalid
  s-expression.

  ## Example:

      iex> import SymbolicExpression.Parser.Sigil
      iex> ~p|(1 2 3)|
      [1, 2, 3]
      iex> ~p|((1 2 3) (4 5 6) (7 8 9))|
      [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
      iex> ~p|(1
      ...> 2
      ...> 3)|
      [1, 2, 3]
  """
  def sigil_p(exp, _opts) do
    SymbolicExpression.Parser.parse! exp
  end
end
