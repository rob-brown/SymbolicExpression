defmodule SymbolicExpressionParserTest do
  use ExUnit.Case, async: true
  alias SymbolicExpression.Parser
  import SymbolicExpression.Sigil

  @moduletag :parser

  test "parse empty string" do
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

  test "parse nested" do
    result = ~p|(() (1 2 3) (4 5 6) (7 8 9) (()))|
    expected = [[], [1, 2, 3], [4, 5, 6], [7, 8, 9], [[]]]
    assert result == expected
  end

  test "parse new lines" do
    result = ~p"""
    (1 2
    3 4 hello
    world
    "test")
    """
    expected = [1, 2, 3, 4, :hello, :world, "test"]
    assert result == expected
  end

  test "parse nesting with new lines" do
    result = ~p"""
    (a
      (b "test"
        (c one)
        (c two)))
    """
    expected = [:a, [:b, "test", [:c, :one], [:c, :two]]]
    assert result == expected
  end

  test "fail to parse bogus s-expression" do
    exp = ~S|bogus|
    assert Parser.parse(exp) == {:error, :bad_arg}
    assert_raise ArgumentError, fn -> Parser.parse!(exp) end
  end

  test "fail to parse extra close paren" do
    exp = ~S|(1 2 3))|
    assert Parser.parse(exp) == {:error, :bad_arg}
    assert_raise ArgumentError, fn -> Parser.parse!(exp) end
  end

  test "fail to parse unclosed paren" do
    exp = ~S|((1 2 3)|
    assert Parser.parse(exp) == {:error, :bad_arg}
    assert_raise ArgumentError, fn -> Parser.parse!(exp) end
  end

  test "fail to parse multiple s-expressions" do
    exp = ~S|()()|
    assert Parser.parse(exp) == {:error, :bad_arg}
    assert_raise ArgumentError, fn -> Parser.parse!(exp) end
  end

  test "fail to parse just comment" do
    assert_raise ArgumentError, fn -> ~p"; Just a comment" end
  end

  test "parse s-expression with starting comment" do
    assert [1, 2, 3] == ~p"""
    ; A starting comment
    (1 2 3)
    """
  end

  test "parse s-expression with ending comment" do
    assert [1, 2, 3] == ~p"""
    (1 2 3)
    ; An ending comment
    """
  end

  test "parse s-expression with intermediate comment" do
    assert [1, 2, 3] == ~p"""
    (1
    ; An intermediate comment
    2
    ; Another intermediate comment
    3)
    """
  end

  test "parse s-expression with inline comment" do
    assert [1, 2, 3] == ~p"""
    (1 ; A one
    2 ; A two
    3) ; A three
    """
  end

  test "parse s-expression with comment containing s-expression" do
    assert [1, 2, 3] == ~p"""
    ; (do not parse)
    (1 2 3)
    ; (4 5 6)
    """
  end

  test "parse file" do
    expected = [:a, [:b, "test", [:c, :one], [:c, :two]]]
    file = [__DIR__, "test.sexp"] |> Path.join |> Path.expand
    assert {:ok, expected} == Parser.parse_file file
    assert expected == Parser.parse_file! file
  end
end
