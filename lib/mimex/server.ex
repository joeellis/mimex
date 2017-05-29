defmodule Mimex.Server do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: :mimex_server])
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get, module, function}, _from, state) do
    if Map.has_key?(state, module) do
      functions = state[module]

      if Map.has_key?(functions, function) do
        {:reply, functions[function], state}
      else
        {:reply, {:error, :function_not_found}, state}
      end
    else
      {:reply, {:error, :module_not_found}, state}
    end
  end

  def handle_cast({:update, module, function_name, response}, state) do
    state = case Map.has_key?(state, module) do
      false -> Map.put(state, module, %{})
      true -> state
    end

    new_state = put_in(state, [module, function_name], response)

    {:noreply, new_state}
  end
end
