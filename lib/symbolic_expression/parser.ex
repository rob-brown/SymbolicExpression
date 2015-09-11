defmodule SymbolicExpression.Parser do
  alias SymbolicExpression.Parser.State

  @whitespace [?\n, ?\s, ?\t]
  @string_terminals [?"]
  @escaped_characters [?"]

  @doc """
  Parses an s-expression held in a string. Returns `{:ok, result}` on success,
  `{:error, reason}` when the string does not contain a valid s-expression.
  See [Wikipedia](https://en.wikipedia.org/wiki/S-expression) for more details
  about s-expressions.

  ## Example

      iex> alias SymbolicExpression.Parser
      iex> Parser.parse ~S|(1 2 3)|
      {:ok, [1, 2, 3]}
      iex> Parser.parse "invalid"
      {:error, :bad_arg}
  """
  def parse(exp) when is_binary(exp) do
    try do
      {:ok, parse!(exp)}
    rescue
      _ in [ArgumentError] ->
        {:error, :bad_arg}
    end
  end

  @doc """
  Like `parse/1`, except raises an `ArgumentError` when the string does not
  contain a valid s-expression.

  ## Example

      iex> alias SymbolicExpression.Parser
      iex> Parser.parse! ~S|(1 2 3)|
      [1, 2, 3]
      iex> try do
      iex>   Parser.parse! "invalid"
      iex> rescue
      iex>   _ in [ArgumentError] ->
      iex>     :exception_raised
      iex> end
      :exception_raised
  """
  def parse!(""), do: []
  def parse!(exp) when is_binary(exp), do: _parse!(State.new exp)

  # New scope
  defp _parse!(s = %State{expression: "(" <> rest, in_term: false, paren_count: count, result: result}) when count > 0 or result == [[]] do
    _parse! %State{s | expression: rest, paren_count: count + 1, result: [[] | s.result]}
  end

  # End scope with no current term.
  defp _parse!(s = %State{expression: ")" <> rest, term: "", in_term: false, paren_count: count, result: [first, second | tail]}) when count > 0 do
    _parse! %State{s | expression: rest, paren_count: count - 1, result: [second ++ [first] | tail]}
  end

  # End scope with current term.
  defp _parse!(s = %State{expression: ")" <> rest, in_term: false, paren_count: count, result: [first, second | tail]}) when count > 0 do
    _parse! %State{s | expression: rest, term: "", paren_count: count - 1, result: [second ++ [first ++ [process s.term]] | tail]}
  end

  # Insignificant whitespace.
  defp _parse!(s = %State{expression: << c :: utf8 >> <> rest, term: "", in_term: false}) when c in @whitespace do
    _parse! %State{s | expression: rest}
  end

  # Significant whitespace.
  defp _parse!(s = %State{expression: << c :: utf8 >> <> rest, in_term: false, result: [head | tail]}) when c in @whitespace do
    _parse! %State{s | expression: rest, term: "", result: [head ++ [process s.term] | tail]}
  end

  # Open or close quoted string.
  defp _parse!(s = %State{expression: << c :: utf8 >> <> rest}) when c in @string_terminals do
    _parse! %State{s | expression: rest, term: s.term <> <<c>>, in_term: !s.in_term}
  end

  # Escaped characters.
  defp _parse!(s = %State{expression: << ?\\, c :: utf8 >> <> rest}) when c in @escaped_characters do
    _parse! %State{s | expression: rest, term: s.term <> <<c>>}
  end

  # Append character to current term.
  defp _parse!(s = %State{expression: << c :: utf8 >> <> rest}) do
    _parse! %State{s | expression: rest, term: s.term <> <<c>>}
  end

  # Base case.
  defp _parse!(%State{expression: "", term: "", in_term: false, paren_count: 0, result: [[head | _]| _]}), do: head

  # Catch all for errors.
  defp _parse!(s) do
    raise ArgumentError, message: """
      Invalid s-expression with
        remaining exp: #{inspect s.expression}
        term: #{inspect s.term}
        in term: #{inspect s.in_term}
        result #{inspect s.result}
    """
  end

  defp process(term) do
    process_int(term) || process_float(term) || process_quoted_string(term) || process_atom(term)
  end

  defp process_int(term) do
    case Integer.parse(term) do
      {int, ""} ->
        int
      _ ->
        nil
    end
  end

  defp process_float(term) do
    case Float.parse(term) do
      {float, ""} ->
        float
      _ ->
        nil
    end
  end

  defp process_quoted_string(term) do
    case ~R/^["](.*)["]$/ |> Regex.run(term) do
      [^term, match] ->
        match
      _ ->
        nil
    end
  end

  defp process_atom(term), do: String.to_atom(term)
end
