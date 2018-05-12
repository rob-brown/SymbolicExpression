defmodule SymbolicExpression.Writer do

  @doc """
  Converts the abstract representation of an s-expression into a string holding
  an s-expression. Returns `{:ok, result}` on success, `{:error, reason}`
  otherwise.

  ## Example

      iex> alias SymbolicExpression.Writer
      iex> Writer.write [1, 2, 3]
      {:ok, "(1 2 3)"}
      iex> Writer.write [%{invalid: true}]
      {:error, :bad_arg}
  """
  def write(exp) when is_list(exp) do
    try do
      {:ok, write!(exp)}
    rescue
      _ in [ArgumentError] ->
        {:error, :bad_arg}
    end
  end

  @doc """
  Like `write/1` except throws an exception on error.

  ## Example

      iex> alias SymbolicExpression.Writer
      iex> Writer.write! [1, 2, 3]
      "(1 2 3)"
      iex> try do
      iex>   Writer.write! [%{invalid: true}]
      iex> rescue
      iex>   _ in [ArgumentError] ->
      iex>     :exception_raised
      iex> end
      :exception_raised
  """
  def write!(exp) when is_list(exp), do: _write!(exp, "")

  defp _write!([head | tail], result), do: _write!(tail, result <> " " <> format(head))
  defp _write!([], result), do: result |> String.trim |> (&"(#{&1})").()

  # Catch all for errors.
  defp _write!(exp, result) do
    raise ArgumentError, message: """
      Invalid s-expression with
        remaining expression: #{inspect exp}
        current result: #{inspect result}
    """
  end

  defp format(x) when is_list(x), do: _write!(x, "")
  defp format(x) when is_binary(x), do: ~s|"#{x}"|
  defp format(x) when is_atom(x), do: Atom.to_string(x)
  defp format(x) when is_integer(x), do: Integer.to_string(x)
  defp format(x) when is_float(x), do: :erlang.float_to_binary(x, [{:decimals, 8}, :compact])
  defp format(x) do
    raise ArgumentError, message: """
      Unable to format "#{inspect x}" for s-expression.
    """
  end
end
