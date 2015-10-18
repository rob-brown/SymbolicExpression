defmodule CanonicalSymbolicExpressionParserTest do
  use ExUnit.Case, async: true
  alias SymbolicExpression.Canonical.Parser
  import SymbolicExpression.Sigil

  @moduletag :parser

  test "parse empty string" do
    assert ~p||c == []
  end

  test "parse empty s-expression" do
    assert ~p|()|c == []
  end

  test "parse 1 element" do
    assert ~p|(1:1)|c == [1]
  end

  test "parse 2 elements" do
    assert ~p|(1:11:2)|c == [1, 2]
  end

  test "parse 3 elements" do
    assert ~p|(1:11:21:3)|c == [1, 2, 3]
  end

  test "parse mixed strings and numbers" do
    result = ~p|(1:12:a22:3a[24:text/plain;charset=utf-8]1:43:5.0[24:text/plain;charset=utf-8]11:hello world[24:text/plain;charset=utf-8]2:42[24:text/plain;charset=utf-8]3:(hi[24:text/plain;charset=utf-8]4:bye)[24:text/plain;charset=utf-8]2:()[24:text/plain;charset=utf-8]2:)([24:text/plain;charset=utf-8]8:" test ")|c
    expected = [1, :a2, :"3a", "4", 5.0, "hello world", "42", "(hi", "bye)", "()", ")(", "\" test \""]
    assert result == expected
  end

  test "parse nested" do
    result = ~p|(()(1:11:21:3)(1:41:51:6)(1:71:81:9)(()))|c
    expected = [[], [1, 2, 3], [4, 5, 6], [7, 8, 9], [[]]]
    assert result == expected
  end

  test "fail to parse bogus s-expression" do
    exp = ~S|bogus|
    assert Parser.parse(exp) == {:error, :bad_arg}
    assert_raise ArgumentError, fn -> Parser.parse!(exp) end
  end

  test "fail to parse extra close paren" do
    exp = ~S|(1:11:21:3))|
    assert Parser.parse(exp) == {:error, :bad_arg}
    assert_raise ArgumentError, fn -> Parser.parse!(exp) end
  end

  test "fail to parse unclosed paren" do
    exp = ~S|((1:11:21:3)|
    assert Parser.parse(exp) == {:error, :bad_arg}
    assert_raise ArgumentError, fn -> Parser.parse!(exp) end
  end

  test "fail to parse multiple s-expressions" do
    exp = ~S|()()|
    assert Parser.parse(exp) == {:error, :bad_arg}
    assert_raise ArgumentError, fn -> Parser.parse!(exp) end
  end

  test "parse file" do
    expected = [:a, [:b, "test", [:c, :one], [:c, :two]]]
    file = [__DIR__, "test.csexp"] |> Path.join |> Path.expand
    assert {:ok, expected} == Parser.parse_file file
    assert expected == Parser.parse_file! file
  end
end
