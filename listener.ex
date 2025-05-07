defmodule Listener do
  use GenServer

  ## Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: :listener)
  end

  ## Server Callbacks

  @impl true
  def init(:ok) do
    IO.puts("[#{Node.self()}] Listener started")
    {:ok, %{}}
  end

  @impl true
  def handle_info({:broadcast, msg}, state) do
    IO.puts("[#{Node.self()}] Received broadcast: #{inspect(msg)}")
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
