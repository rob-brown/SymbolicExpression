defmodule SymbolicExpression.Sigil do

  @doc """
  Takes an s-expression or canonical s-expression and parses it. Throws an
  exception when given an invalid s-expression or canonical s-expression. By
  default, the sigil parses the input as a standard s-expression. Adding the `c`
  option will parse the input as a canonical s-expression.

  ## Example:

      iex> import SymbolicExpression.Sigil
      iex> ~p|(1 2 3)|
      [1, 2, 3]
      iex> ~p|((1 2 3) (4 5 6) (7 8 9))|
      [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
      iex> ~p|(1
      ...> 2
      ...> 3)|
      [1, 2, 3]
      iex> ~p|(1:11:21:3)|c
      [1, 2, 3]
      iex> ~p|((1:11:21:3)(1:41:51:6)(1:71:81:9))|c
      [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
      iex> ~p|((1:11:21:3)[24:text/plain;charset=utf-8]14:This is a test4:atom())|c
      [[1, 2, 3], "This is a test", :atom, []]
  """
  def sigil_p(exp, 'c') do
    SymbolicExpression.Canonical.Parser.parse! exp
  end
  def sigil_p(exp, _opts) do
    SymbolicExpression.Parser.parse! exp
  end
end
