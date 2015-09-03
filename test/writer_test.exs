defmodule SymbolicExpressionWriterTest do
  use ExUnit.Case, async: true
  alias SymbolicExpression.Writer

  @tag :writer
  @tag :doctest
  doctest SymbolicExpression.Writer

  @tag :writer
  test "write empty s-expression" do
    assert Writer.write!([]) == "()"
  end

  @tag :writer
  test "write 1 element" do
    assert Writer.write!([1]) == "(1)"
  end

  @tag :writer
  test "write 2 elements" do
    assert Writer.write!([1, 2]) == "(1 2)"
  end

  @tag :writer
  test "write 3 elements" do
    assert Writer.write!([1, 2, 3]) == "(1 2 3)"
  end

  @tag :writer
  test "write mixed strings and numbers" do
    result = Writer.write! [1, :a2, :"3a", "4", 5.0, "hello world", "42", "(hi", "bye)", "()", ")(", "\" test \""]
    expected = ~s|(1 a2 3a "4" 5.0 "hello world" "42" "(hi" "bye)" "()" ")(" "\" test \"")|
    assert result == expected
  end

  @tag :writer
  test "write nested" do
    result = Writer.write! [[], [1, 2, 3], [4, 5, 6], [7, 8, 9], [[]]]
    expected = ~s|(() (1 2 3) (4 5 6) (7 8 9) (()))|
    assert result == expected
  end

end
