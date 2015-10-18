defmodule SymbolicExpression.Canonical.Parser do
  alias SymbolicExpression.Canonical.Parser.State
  require Logger

  @doc """
  Parses a canonical s-expression held in a string. Returns `{:ok, result}` on
  success, `{:error, reason}` when the string does not contain a valid canonical
  s-expression. See [Wikipedia](https://en.wikipedia.org/wiki/Canonical_S-expressions)
  for more details about canonical s-expressions.

  ## Example

      iex> alias SymbolicExpression.Canonical.Parser
      iex> Parser.parse "(1:11:21:3)"
      {:ok, [1, 2, 3]}
      iex> Parser.parse "invalid"
      {:error, :bad_arg}
  """
  def parse(exp) when is_binary(exp) do
    try do
      {:ok, parse!(exp)}
    rescue
      error in [ArgumentError] ->
        Logger.error "Failed to parse expression: '#{exp}' with error: '#{inspect error}'"
        {:error, :bad_arg}
    end
  end

  @doc """
  Like `parse/1`, except raises an `ArgumentError` when the string does not
  contain a valid s-expression.

  ## Example

      iex> alias SymbolicExpression.Canonical.Parser
      iex> Parser.parse! "(1:11:21:3)"
      [1, 2, 3]
      iex> Parser.parse! "((1:11:21:3)[24:text/plain;charset=utf-8]14:This is a test4:atom())"
      [[1, 2, 3], "This is a test", :atom, []]
  """
  def parse!(""), do: []
  def parse!(exp) when is_binary(exp), do: _parse!(State.new exp)

  @doc """
  Like `parse/1` except the input is a file path instead of a binary.
  """
  def parse_file(file) when is_binary(file) do
    try do
      {:ok, parse_file!(file)}
    rescue
      error in [ArgumentError] ->
        Logger.error "Failed to parse expression in file: '#{file}' with error: '#{inspect error}'"
        {:error, :bad_arg}
      error in [File.Error] ->
        Logger.error "Failed to parse expression in file: '#{file}' with error: '#{inspect error}'"
        {:error, :bad_file}
    end
  end

  @doc """
  Like `parse_file/1` except raises `ArgumentError` when the string does not
  contain a valid s-expression or `File.Error` if the file can't be read.
  """
  def parse_file!(file) when is_binary(file) do
    file |> Path.expand |> File.read! |> parse!
  end

  # New scope.
  defp _parse!(s = %State{expression: "(" <> rest, in_term: false, paren_count: count, result: result}) when count > 0 or result == [[]] do
    _parse! %State{s | expression: rest, paren_count: count + 1, result: [[] | s.result]}
  end

  # End scope with no current term.
  defp _parse!(s = %State{expression: ")" <> rest, token: "", in_term: false, paren_count: count, result: [first, second | tail]}) when count > 0 do
    _parse! %State{s | expression: rest, paren_count: count - 1, result: [second ++ [first] | tail]}
  end

  # Start type.
  defp _parse!(s = %State{expression: "[" <> rest, in_term: false, in_type: false}) do
    _parse! %State{s | expression: rest, in_type: true}
  end

  # # End scope with no current term.
  # defp _parse!(s = %State{expression: "]" <> rest, in_term: false, in_type: true}) do
  #   _parse! %State{s | expression: rest, in_type: false}
  # end

  # End length string.
  defp _parse!(s = %State{expression: ":" <> rest, in_term: false}) do
    length = parse_length s.token
    _parse! %State{s | expression: rest, token: "", in_term: true, term_length: length}
  end

  # Done parsing type
  defp _parse!(s = %State{expression: << c :: utf8, ?] >> <> rest, in_term: true, in_type: true, term_length: 1}) do
    type = s.token <> <<c>>
    _parse! %State{s | expression: rest, token: "", in_term: false, in_type: false, term_length: 0, type: type}
  end

  # Done parsing term
  defp _parse!(s = %State{expression: << c :: utf8 >> <> rest, in_term: true, term_length: 1, result: [head | tail]}) do
    processed = process(s.token <> <<c>>, s.type)
    _parse! %State{s | expression: rest, token: "", type: "", in_term: false, term_length: 0, result: [head ++ [processed] | tail]}
  end

  # Grab next character of term.
  defp _parse!(s = %State{expression: << c :: utf8 >> <> rest, in_term: true, term_length: length}) when length > 1 do
    _parse! %State{s | expression: rest, token: s.token <> <<c>>, term_length: length - 1}
  end

  # Append character to current term.
  defp _parse!(s = %State{expression: << c :: utf8 >> <> rest}) do
    _parse! %State{s | expression: rest, token: s.token <> <<c>>}
  end

  # Base case.
  defp _parse!(%State{expression: "", token: "", in_term: false, paren_count: 0, result: [[head | _]| _]}), do: head

  # Catch all for errors.
  defp _parse!(s) do
    raise ArgumentError, message: """
      Invalid s-expression with
        remaining exp: #{inspect s.expression}
        token: #{inspect s.token}
        in term: #{inspect s.in_term}
        result #{inspect s.result}
    """
  end

  defp parse_length(string) when is_binary(string) do
    string |> Integer.parse |> _parse_length(string)
  end
  defp _parse_length({0, _}, _) do
    raise ArgumentError, message: "Term length of 0 is not allowed."
  end
  defp _parse_length({length, ""}, _), do: length
  defp _parse_length(_, string) do
    raise ArgumentError, message: "Expected a term length, got '#{string}'"
  end

  defp process(term, type) do
    process_from_type(term, type)
    || process_int(term, type)
    || process_float(term, type)
    || process_atom(term, type)
  end

  defp process_from_type(_term, ""), do: nil
  defp process_from_type(term, "text/plain;charset=utf-8"), do: term
  defp process_from_type(term, type) do
    raise ArgumentError, message: "Unabled to process type: '#{inspect type}' for term: '#{inspect term}'"
  end

  defp process_int(term, "") do
    case Integer.parse(term) do
      {int, ""} ->
        int
      _ ->
        nil
    end
  end

  defp process_float(term, "") do
    case Float.parse(term) do
      {float, ""} ->
        float
      _ ->
        nil
    end
  end

  defp process_atom(term, ""), do: String.to_atom(term)
end
