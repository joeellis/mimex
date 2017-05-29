Code.compiler_options(ignore_module_conflict: true)

defmodule TestFoo do
  def add(this, that) do
    this + that
  end
end

defmodule TestBar do
  def multi(this, that) do
    this * that
  end
end

defmodule MimexTest do
  use ExUnit.Case

  import Mimex

  test "can stub a single module" do
    stub_module = Mimex.stub(TestFoo)

    expects stub_module, :add, fn (this, that) -> this - that end

    assert stub_module.add(4, 2) == 2 # stubbed copy shows new value
    assert TestFoo.add(4, 2) == 6 # original module is not modified
  end

  test "can stub multiple modules do" do
    [stub_mod_1, stub_mod_2] = Mimex.stub([TestFoo, TestBar])

    expects stub_mod_1, :add, fn (this, that) -> this - that end
    expects stub_mod_2, :multi, fn (this, that) -> this / that end

    assert stub_mod_1.add(4, 2) == 2 # stubbed copy shows new value
    assert stub_mod_2.multi(4, 2) == 2 # stubbed copy shows new value

    assert TestFoo.add(4, 2) == 6 # original module is not modified
    assert TestBar.multi(4, 2) == 8 # original module is not modified
  end

  test "can't set a function on a method that doesn't exist" do
    stub_module = Mimex.stub(TestFoo)

    assert_raise UndefinedFunctionError, fn ->
      stub_module.other_method(4, 2) == 2
    end
  end
end


