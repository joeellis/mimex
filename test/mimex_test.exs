defmodule MimexTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = Mimex.start_link([Foo])
    {:ok, pid: pid}
  end

  test "the truth" do
    Mimex.Foo.expect :test_call, fn (this, that) -> [this, that] end

    assert Mimex.Foo.get(:test_call).(1, 2) == [1,2]
  end
end
