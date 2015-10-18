defmodule SymbolicExpression.Canonical.Parser.State do
  defstruct expression: "", token: "", type: "", in_term: false, term_length: 0, in_type: false, paren_count: 0, result: [[]]

  def new(exp), do: %__MODULE__{expression: exp}
end
