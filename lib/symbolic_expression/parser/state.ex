defmodule SymbolicExpression.Parser.State do
  defstruct expression: "", term: "", in_term: false, in_comment: false, paren_count: 0, result: [[]]

  def new(exp), do: %__MODULE__{expression: exp}
end
