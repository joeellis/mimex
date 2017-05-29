defmodule Mimex do
  use GenServer

  def stub(modules) when is_list(modules), do: Enum.map(modules, &stub/1)
  def stub(module) do
    stub_mod = Module.concat(__MODULE__, module)
    module_functions = stub_module_fn(module)

    Module.create(stub_mod, module_functions, Macro.Env.location(__ENV__))

    stub_mod
  end

  def list do
    GenServer.call(:mimex_server, :list)
  end

  def get(module, function_name) do
    GenServer.call(:mimex_server, {:get, module, function_name})
  end

  def expects(module, function_name, response) do
    GenServer.cast(:mimex_server, {:update, module, function_name, response})
  end

  defp stub_module_fn(module) do
    functions = module.__info__(:functions)

    Enum.map(functions, fn {name, arity} ->
      params = for x <- 1..arity, do: Macro.var(:"arg#{x}", module)
      mimex_module = Module.concat(__MODULE__, module)

      quote do
        def unquote(name)(unquote_splicing(params)) do
          unquote(__MODULE__).get(unquote(mimex_module), unquote(name)).(unquote_splicing(params))
        end
      end
    end)
  end
end
