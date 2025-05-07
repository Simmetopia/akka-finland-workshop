# Agenda

- Welcome and Expectations
- Syntax and Standard Library Tour
- GenServers and the OTP Model
- Runtime and Observability
- Break
- Hands-on Workshop
- Wrap-up and Q&A

<!-- end_slide -->

# Welcome and Expectations

## Overview of the session

+ Today we'll cover:
  - Elixir syntax and functional paradigms
  - OTP and the actor model
  - BEAM runtime advantages
+ Format:
  - Theory → Practice → Hands-on

<!-- end_slide -->

## Why Elixir for Scala/Akka devs?

+ Common ground:
  - Functional programming
  - Actor-based concurrency
+ Key advantages:
  - Simpler syntax
  - Lower memory footprint
  - Built-in fault tolerance

Simo thought it could be interesting :)

<!-- end_slide -->

## Functional roots and BEAM's strengths

+ Elixir's foundation:
  - Immutable data structures
  - Pattern matching
+ BEAM advantages:
  - Lightweight processes (~2KB vs JVM threads)
  - Preemptive scheduling
  - "Let it crash" philosophy

<!-- end_slide -->

# Syntax and Standard Library Tour

## Pattern matching

```elixir
# Basic pattern matching
{:ok, result} = {:ok, "success"}

# Function clauses
def process({:ok, result}), do: result
def process({:error, reason}), do: raise(reason)

# With collections
[head | tail] = [1, 2, 3, 4]  # head = 1, tail = [2, 3, 4]
```

<!-- end_slide -->

## Piping and function chaining

```elixir
# Without pipes
String.downcase(String.trim("  HELLO  "))

# With pipes
"  HELLO  "
|> String.trim()
|> String.downcase()

# Multiple transformations
[1, 2, 3, 4, 5]
|> Enum.filter(fn x -> rem(x, 2) == 0 end)
|> Enum.map(fn x -> x * 2 end)
|> Enum.sum()
```

<!-- end_slide -->

## Immutability

```elixir
# All data is immutable
map = %{a: 1, b: 2}
new_map = Map.put(map, :c, 3)

# Original is unchanged
map        # %{a: 1, b: 2}
new_map    # %{a: 1, b: 2, c: 3}

# Syntactic sugar for updates
user = %{name: "Joe", age: 30}
older_user = %{user | age: 31}
```

<!-- end_slide -->

## Enum, Map, List, Tuple

```elixir
# Enum - higher-order functions for collections
Enum.reduce([1, 2, 3], 0, fn x, acc -> x + acc end)

# Maps with string keys
map = %{"name" => "Alice", "age" => 30}

# Maps with atom keys
user = %{name: "Bob", age: 25}
user.name  # "Bob"

# Lists and Tuples
list = [1, 2, 3]   # Linked list, good for prepending
tuple = {1, "a", :atom}  # Fixed-size, fast access
```

<!-- end_slide -->

## Comparisons to Scala collections

+ Scala → Elixir equivalents:
  - List → List (but no random access)
  - Map → Map
  - Set → MapSet
  - Tuple → Tuple
+ Differences:
  - No built-in mutable collections
  - Functional approach (not OO)
  - No type parameters

<!-- end_slide -->

# GenServers and the OTP Model

## What is a GenServer?

+ Generic Server behavior:
  - Abstracts client-server interactions
  - Synchronous and asynchronous calls
  - Manages state

This is the core of elixir.

**Think a small city, that can only communicate with messages, and each
houses mailbox is a queue taken from fifo**

<!-- end_slide -->

The simpelts genserver is just an agent
```elixir
defmodule MyApp.Test do
  use Agent

  def start_link do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def increment() do
    Agent.update(__MODULE__, &(&1 + 1))
  end

  def get() do
    Agent.get(__MODULE__, & &1)
  end
end
```

<!-- end_slide -->

# GenServer API
A more normal is an actual genserver an this handles abitrary messages/state

```elixir
defmodule Counter do
  use GenServer

  # Client API
  def start_link(initial_count) do
    GenServer.start_link(__MODULE__, initial_count)
  end

  def increment(pid) do
    GenServer.cast(pid, :increment)
  end

  def get_count(pid) do
    GenServer.call(pid, :get_count)
  end
end
```

<!-- end_slide -->

## Callbacks (init, handle_call, handle_cast, etc.)

```elixir
# Inside the Counter module:

# Server callbacks
def init(initial_count) do
  {:ok, initial_count}
end

def handle_call(:increment,_from, count) do
  {:reply, count + 1, count + 1}
end

def handle_call(:get_count, _from, count) do
  {:reply, count, count}
end

# Usage
{:ok, pid} = Counter.start_link(0)
Counter.increment(pid)
Counter.get_count(pid)  # 1
```

<!-- end_slide -->

## State and concurrency

+ Each GenServer:
  - Has isolated state
  - Processes messages sequentially
  - Never shares memory

```elixir
# Create many counters
counters = for _ <- 1..1000 do
  {:ok, pid} = Counter.start_link(0)
  pid
end

# Increment them all concurrently
counters |> Enum.each(&Counter.increment/1)

# Check their values
counters |> Enum.map(&Counter.get_count/1)
```

<!-- end_slide -->

## Supervision and fault tolerance

Supervision is this:
```
               +------------------+
               |   Supervisor     |
               |  (Elixir Process)|
               +------------------+
                     /      \
                    /        \
                   v          v
         +----------------+  +----------------+
         |   Child 1      |  |   Child 2      |
         | (Worker/Task)  |  | (Worker/Task)  |
         +----------------+  +----------------+
```
## Supervision and fault tolerance

Strategies: one_for_one, one_for_all, rest_for_one

Kubernetes like resillience
<!-- end_slide -->

```elixir
defmodule CounterSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    children = [
      {Counter, 0}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

<!-- end_slide -->

## Comparison to Akka actors and supervision

+ Similarities:
  - Actor model for concurrency
  - Hierarchical supervision
  - Message passing

+ Differences:
  - Akka: library on JVM
  - Elixir: native to BEAM
  - Akka: heavyweight threads (but bundled together)
  - Elixir: lightweight processes
  - Elixir: simpler API

<!-- end_slide -->

# Runtime and Observability

## Using Iex for introspection

+ Runtime REPL for inspecting:
  - Process state
  - System metrics
  - Memory usage

```elixir
# In IEx (Elixir's interactive shell)
iex> pid = Process.whereis(:my_registered_process)
iex> Process.info(pid)
iex> :observer.start()  # Launch graphical observer
```

<!-- end_slide -->

## Tracing with `:recon_trace`

+ Real-time tracing without stopping:
  - Function calls
  - Message passing
  - Process creation/termination

```elixir
# Trace all calls to Counter.increment/1
:recon_trace.calls({Counter, :increment, 1}, 100)

# Trace process messages
:recon_trace.calls({GenServer, :call, fun: &:erlang.display/1}, 10)
```

<!-- end_slide -->

## Monitoring live processes

+ Built-in tools:
  - :observer
  - Process.monitor/1
  - Application metrics

```elixir
# Monitor a process for crashes
ref = Process.monitor(pid)
receive do
  {:DOWN, ^ref, :process, ^pid, reason} ->
    IO.puts("Process terminated: #{inspect(reason)}")
end
```

<!-- end_slide -->

## Hot code upgrades (brief mention)

+ Upgrade running systems without restart:
  - Release handling
  - Code_Server module
  - No downtime required

```elixir
# In a release, define upgrade code
defmodule AppUpgrader do
  def upgrade do
    # Handle state migrations
  end
end
```

<!-- end_slide -->

# Break

<!-- end_slide -->

# Hands-on Workshop

## Distributed Hello

```elixir
defmodule MyApp.Remote do
  def hello(from) do
    IO.puts("[#{node()}] Hello.YourName.hello/0 called on #{Node.self()}")
    "Hello from #{from}"
  end
end

# Start distributed nodes:
# Computer 1: iex --name node1@<local-ip> --cookie <secret>
# Computer 2: iex --name node2@<local-ip> --cookie <secret>

# Connect nodes:
Node.connect(:'node2@127.0.0.1')
Node.list()  # Verify connection

# Call remotely:
:rpc.call(:'node2@127.0.0.1', Hello.YourName, :hello, [])
```

<!-- end_slide -->
## Distributed Hello
Can you see the log on 1, and the output on 2?

<!-- end_slide -->
## Distributed Hello
```elixir
  def hello2(from) do
    spawn(fn ->
      # Instead of using the caller's group leader, use the local node's group leader
      # This will make IO.puts output on the original node (where the function is defined)
      :erlang.group_leader(:erlang.whereis(:user), self())
      IO.puts("[#{from}] called MyApp.Remote.hello/1 called on #{Node.self()}")
    end)

    "Hello from #{from}"
  end
```

<!-- end_slide -->


## GenServer: Shared Counter

- Build a `Counter` GenServer with `:increment`, `:decrement`, `:get`
- Allow remote access via `:rpc`
- Optional: use `Registry` or `:global` for node-aware naming

```elixir
# Make the Counter globally registered
def start_link(initial_count) do
  GenServer.start_link(__MODULE__, initial_count,
                       name: {:global, __MODULE__})
end

# Access from any node
:rpc.call(node, GenServer, :call, [{:global, Counter}, :get_count])
```

<!-- end_slide -->

## Supervised Crasher

- A GenServer that crashes when it receives `:boom`
- Supervised with a `Supervisor`
- Observe restarts, show `:recon_trace`

```elixir
def handle_cast(:boom, _state) do
  raise "Boom!"
end

# From IEx:
:sys.get_state(pid)
GenServer.cast(pid, :boom)  # Watch it crash and restart
:sys.get_state(pid)  # New state after restart
```

<!-- end_slide -->

## Bonus

- Broadcast messages to all connected nodes
- Gossip-style update system

```elixir
# Broadcast to all nodes
defmodule Broadcaster do
  def send_all(message) do
    Node.list() ++ [Node.self()]
    |> Enum.each(fn node ->
      send({:listener, node}, {:broadcast, message})
    end)
  end
end
```

<!-- end_slide -->

# Wrap-up and Q&A

## Reflections and key takeaways

+ Elixir strengths:
  - Lightweight concurrency
  - Functional purity
  - Fault tolerance
  - Developer happiness

+ Consider for:
  - Real-time systems
  - Massively concurrent apps
  - Distributed systems

<!-- end_slide -->

## How Elixir fits into modern system design

+ Ideal for:
  - Microservices
  - IoT and edge computing
  - High-availability systems
  - Real-time data processing

+ Complements other technologies:
  - Phoenix for web
  - Nx for ML workloads
  - LiveView for reactive UIs

<!-- end_slide -->

## Further resources and reading

+ Books:
  - Programming Elixir 1.6+ (Dave Thomas)
  - Elixir in Action (Saša Jurić)
  - Programming Phoenix (Chris McCord)

+ Online:
  - Elixir Forum: elixirforum.com
  - Elixir School: elixirschool.com
  - ElixirConf videos on YouTube

<!-- end_slide -->

# Summary

+ Elixir brings Erlang's power with modern syntax
+ BEAM VM offers unparalleled concurrency
+ OTP abstractions simplify building robust systems
+ Lower cognitive load than Scala/Akka
+ Excellent fit for distributed, fault-tolerant systems

<!-- end_slide -->
