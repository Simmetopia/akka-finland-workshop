defmodule Counter do
  use GenServer

  # Client API
  def start_link(initial_count) do
    GenServer.start_link(__MODULE__, initial_count, name: {:global, SimonsModule})
  end

  def increment() do
    GenServer.call({:global, SimonsModule}, :increment)
  end

  def get_count() do
    GenServer.call({:global, SimonsModule}, :get_count)
  end

  def init(initial_count) do
    {:ok, initial_count}
  end

  def handle_call(:increment, _from, count) do
    {:reply, count + 1, count + 1}
  end

  def handle_call(:get_count, _from, count) do
    {:reply, count, count}
  end

  def handle_cast(:boom, _count) do
    raise "you done did it now"
  end
end
