defmodule SymbolicExpressionParserTest do
  use ExUnit.Case, async: true
  alias SymbolicExpression.Parser
  import SymbolicExpression.Parser.Sigil

  doctest SymbolicExpression.Parser
  doctest SymbolicExpression.Parser.Sigil

  test "empty string" do
    assert ~p|| == []
  end

  test "parse empty s-expression" do
    assert ~p|()| == []
  end

  test "parse 1 element" do
    assert ~p|(1)| == [1]
  end

  test "parse 2 elements" do
    assert ~p|(1 2)| == [1, 2]
  end

  test "parse 3 elements" do
    assert ~p|(1 2 3)| == [1, 2, 3]
  end

  test "parse mixed strings and numbers" do
    result = ~p|(1 a2 3a "4" 5.0 "hello world" "42" "(hi" "bye)" "()" ")(" "\" test \"")|
    expected = [1, :a2, :"3a", "4", 5.0, "hello world", "42", "(hi", "bye)", "()", ")(", "\" test \""]
    assert result == expected
  end

  test "nested" do
    result = ~p|(() (1 2 3) (4 5 6) (7 8 9) (()))|
    expected = [[], [1, 2, 3], [4, 5, 6], [7, 8, 9], [[]]]
    assert result == expected
  end

  test "new line" do
    result = ~p"""
    (1 2
    3 4 hello
    world
    "test")
    """
    expected = [1, 2, 3, 4, :hello, :world, "test"]
    assert result == expected
  end

  test "nesting with new lines" do
    result = ~p"""
    (a
      (b "test"
        (c one)
        (c two)))
    """
    expected = [:a, [:b, "test", [:c, :one], [:c, :two]]]
    assert result == expected
  end

  test "bogus s-expression" do
    exp = ~S|bogus|
    assert Parser.parse(exp) == nil
    assert_raise ArgumentError, fn -> Parser.parse!(exp) end
  end

  test "extra close paren" do
    exp = ~S|(1 2 3))|
    assert Parser.parse(exp) == nil
    assert_raise ArgumentError, fn -> Parser.parse!(exp) end
  end

  test "unclosed paren" do
    exp = ~S|((1 2 3)|
    assert Parser.parse(exp) == nil
    assert_raise ArgumentError, fn -> Parser.parse!(exp) end
  end

  test "multiple s-expressions" do
    exp = ~S|()()|
    assert Parser.parse(exp) == nil
    assert_raise ArgumentError, fn -> Parser.parse!(exp) end
  end
end
