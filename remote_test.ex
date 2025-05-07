defmodule MyApp.Remote do
  def hello(from) do
    IO.puts("[#{node()}] MyApp.Remote.hello/1 called on #{Node.self()}")
    "Hello from #{from}"
  end

  def hello2(from) do
    spawn(fn ->
      # Instead of using the caller's group leader, use the local node's group leader
      # This will make IO.puts output on the original node (where the function is defined)
      :erlang.group_leader(:erlang.whereis(:user), self())
      IO.puts("[#{from}] called MyApp.Remote.hello/1 called on #{Node.self()}")
    end)

    "Hello from #{from}"
  end
end

