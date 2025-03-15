defmodule LazyTeamcity.TeamcityStateServer do
  @moduledoc """
    This server contains only the state updated by the TeamcityFetcher server. It existst only to
    decouple the server responsible to fetching the state and the server responsible for having the state.
  """

  use GenServer

  alias ElixirLS.LanguageServer.Build
  alias LazyTeamcity.Build
  alias LazyTeamcity.Message
  alias LazyTeamcity.Stats
  alias LazyTeamcity.TeamcityState

  # Client

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(nil) do
    {:ok, %TeamcityState{}}
  end

  @spec get_builds() ::
          {latest_builds :: list(Build.t()), running_builds :: list(Build.t()),
           queued_builds_count :: non_neg_integer()}
  def get_builds() do
    GenServer.call(__MODULE__, :builds)
  end

  @spec get_stats() :: Stats.t()
  def get_stats() do
    GenServer.call(__MODULE__, :stats)
  end

  @spec get_messages() :: list(Message.t())
  def get_messages() do
    GenServer.call(__MODULE__, :messages)
  end

  @spec publish_message(String.t()) :: :ok
  def publish_message(message) when is_bitstring(message) do
    GenServer.cast(__MODULE__, {:publish_message, %Message{message: message, datetime: Timex.now()}})
  end

  # Server (callbacks)

  @impl true
  def handle_cast({:publish_messages, new_messages}, %TeamcityState{messages: messages} = state) do
    {:noreply, %TeamcityState{state | messages: new_messages ++ messages}}
  end

  @impl true
  def handle_cast({:publish_message, %Message{} = new_message}, %TeamcityState{messages: messages} = state) do
    {:noreply, %TeamcityState{state | messages: [new_message | messages]}}
  end

  @impl true
  def handle_cast({:publish_builds, new_latest_buuild, new_running_builds}, %TeamcityState{} = state) do
    {:noreply, %TeamcityState{state | latest_builds: new_latest_buuild, running_builds: new_running_builds}}
  end

  @impl true
  def handle_cast({:publish_agents_count, count}, %TeamcityState{} = state) do
    {:noreply, %TeamcityState{state | agents: count}}
  end

  @impl true
  def handle_cast({:publish_queued_builds_count, count}, %TeamcityState{} = state) do
    {:noreply, %TeamcityState{state | queued_builds_count: count}}
  end

  @impl true
  def handle_call(:messages, _from, %{messages: messages} = state) do
    {:reply, messages, %TeamcityState{state | messages: []}}
  end

  @impl true
  def handle_call(:builds, _from, state) do
    %TeamcityState{latest_builds: latest_builds, running_builds: running_builds, queued_builds_count: count} = state
    {:reply, {latest_builds, running_builds, count}, state}
  end

  @impl true
  def handle_call(:stats, _from, %TeamcityState{} = state) do
    %TeamcityState{agents: agents} = state
    {:reply, %Stats{count_agents: agents}, state}
  end
end
