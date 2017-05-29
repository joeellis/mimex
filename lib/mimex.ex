defmodule Mimex do
  use GenServer

  def start_link(modules \\ []) do
    GenServer.start_link(__MODULE__, modules, [name: :mimex])
  end

  def init(modules) do
    Code.compiler_options(ignore_module_conflict: true)

    state = Map.new(modules, &{&1, %{}})

    Enum.each modules, fn(module) ->
      module_name = Module.concat(__MODULE__, module)

      Module.create(module_name, create_mimex_fn(module), Macro.Env.location(__ENV__))

      module_functions = stub_module_fn(module_name)

      Module.create(module, module_functions, Macro.Env.location(__ENV__))
    end

    {:ok, state}
  end

  def list do
    GenServer.call(:mimex, :list)
  end

  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get, provider, function_name}, _from, state) do
    if Map.has_key?(state, provider) do
      provider = state[provider]

      if Map.has_key?(provider, function_name) do
        {:reply, provider[function_name], state}
      else
        {:reply, {:error, :function_not_found}, state}
      end
    else
      {:reply, {:error, :provider_not_found}, state}
    end
  end

  def handle_cast({:update, provider, function_name, response}, state) do
    new_state = put_in(state, [provider, function_name], response)

    {:noreply, new_state}
  end

  defp stub_module_fn(module_name) do
    functions = module_name.__info__(:functions)

    Enum.map(functions, fn {name, arity} ->
      params = for x <- 1..arity, do: Macro.var(:"arg#{x}", module_name)

      quote do
        def unquote(name)(unquote_splicing(params)) do
          module_name = Module.concat(Mimex, unquote(module_name))
          apply(unquote(module_name), :get, [Atom.to_string(unquote(name))]).(unquote(params))
        end
      end
    end)
  end

  defp create_mimex_fn(module) do
    quote do
      def get(function_name) do
        GenServer.call(:mimex, {:get, unquote(module), function_name})
      end

      def expect(function_name, response) do
        GenServer.cast(:mimex, {:update, unquote(module), function_name, response})
      end
    end
  end
end
