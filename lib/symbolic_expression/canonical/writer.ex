defmodule SymbolicExpression.Canonical.Writer do

  @doc """
  Converts the abstract representation of an s-expression into a string holding
  an s-expression in canonical form. Returns `{:ok, result}` on success,
  `{:error, reason}` otherwise.

  ## Example

      iex> alias SymbolicExpression.Canonical.Writer
      iex> Writer.write [1, 2, 3]
      {:ok, "(1:11:21:3)"}
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

      iex> alias SymbolicExpression.Canonical.Writer
      iex> Writer.write! [1, 2, 3]
      "(1:11:21:3)"
      iex> Writer.write! [[1, 2, 3], "This is a test", :atom, []]
      "((1:11:21:3)[24:text/plain;charset=utf-8]14:This is a test4:atom())"
      iex> try do
      iex>   Writer.write! [%{invalid: true}]
      iex> rescue
      iex>   _ in [ArgumentError] ->
      iex>     :exception_raised
      iex> end
      :exception_raised
  """
  def write!(exp) when is_list(exp), do: _write!(exp, "")

  defp _write!([head | tail], result), do: _write!(tail, result <> format(head))
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
  defp format(x) when is_atom(x), do: x |> Atom.to_string |> _format
  defp format(x) when is_integer(x), do: x |> Integer.to_string |> _format
  defp format(x) when is_float(x) do
    #x |> Float.to_string([compact: true, decimals: 8]) |> _format
    :erlang.float_to_binary(x, [:compact, {:decimals, 8}])
  end
  defp format(x) when is_binary(x) do
    "[24:text/plain;charset=utf-8]#{_format x}"
  end
  defp format(x) do
    raise ArgumentError, message: """
      Unable to format "#{inspect x}" for s-expression.
    """
  end

  defp _format(string) when is_binary(string) do
    "#{String.length string}:#{string}"
  end
end
