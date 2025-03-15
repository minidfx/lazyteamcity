defmodule LazyTeamcity.TeamcityFetcherServer do
  use GenServer

  require Logger

  alias LazyTeamcity.Build
  alias LazyTeamcity.Message
  alias LazyTeamcity.TeamcityFetcherState
  alias LazyTeamcity.TeamcityHttpClient

  # Client

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @spec update_count_latest_builds_messages(integer()) :: :ok
  def update_count_latest_builds_messages(count) when is_integer(count) do
    GenServer.cast(__MODULE__, {:latest_builds, count})
  end

  @spec update_count_running_builds_messages(integer()) :: :ok
  def update_count_running_builds_messages(count) when is_integer(count) do
    GenServer.cast(__MODULE__, {:running_builds, count})
  end

  # Server (callbacks)

  @impl true
  def init(_args) do
    _ = Process.send_after(__MODULE__, :loop, 0)
    _ = publish_message("Starting teamcity fetcher ...")

    {:ok, %TeamcityFetcherState{}}
  end

  @impl true
  def handle_info(:loop, %TeamcityFetcherState{} = state) do
    try do
      unsafe_request_teamcity(state)
    catch
      x ->
        _ = looping()
        _ = publish_message(inspect(x))
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:running_builds, count}, %TeamcityFetcherState{} = state) do
    {:noreply, %TeamcityFetcherState{state | count_latest_build: count}}
  end

  @impl true
  def handle_cast({:latest_builds, count}, %TeamcityFetcherState{} = state) do
    {:noreply, %TeamcityFetcherState{state | count_running_build: count}}
  end

  # Private

  defp publish_message(message) when is_bitstring(message),
    do: publish_messages([message])

  defp publish_messages([head | _] = messages)
       when is_list(messages) and is_bitstring(head),
       do:
         GenServer.cast(
           LazyTeamcity.TeamcityStateServer,
           {:publish_messages, Enum.map(messages, fn x -> %Message{datetime: Timex.now(), message: x} end)}
         )

  defp publish_builds(latest_builds, running_builds)
       when is_list(latest_builds) and is_list(running_builds),
       do: GenServer.cast(LazyTeamcity.TeamcityStateServer, {:publish_builds, latest_builds, running_builds})

  defp publish_agents_count(count)
       when is_integer(count) and count >= 0,
       do: GenServer.cast(LazyTeamcity.TeamcityStateServer, {:publish_agents_count, count})

  defp publish_queued_builds_count(count)
       when is_integer(count) and count >= 0,
       do: GenServer.cast(LazyTeamcity.TeamcityStateServer, {:publish_queued_builds_count, count})

  defp looping(),
    do: Process.send_after(__MODULE__, :loop, Application.fetch_env!(:lazy_teamcity, :fetcher_interval_seconds))

  defp unsafe_request_teamcity(%TeamcityFetcherState{count_latest_build: 0, count_running_build: 0} = state) do
    _ = looping()
    state
  end

  defp unsafe_request_teamcity(%TeamcityFetcherState{} = state) do
    %TeamcityFetcherState{count_latest_build: count_latest_build, count_running_build: count_running_build} = state

    with {:ok, running_builds_env} <- TeamcityHttpClient.try_get_running_builds(count_running_build),
         {:ok, latest_builds_env} <- TeamcityHttpClient.try_get_latest_builds(count_latest_build),
         {:ok, connected_agent_env} <- TeamcityHttpClient.try_get_connected_agents(),
         {:ok, queued_builds_env} <- TeamcityHttpClient.try_get_queued_builds_count(),
         %Tesla.Env{body: running_build_as_json} = running_builds_env,
         %Tesla.Env{body: latest_build_as_json} = latest_builds_env,
         %Tesla.Env{body: connected_agent_as_json} = connected_agent_env,
         %Tesla.Env{body: queued_builds_as_json} = queued_builds_env,
         {running_builds, errors1} <- get_builds(running_build_as_json),
         {latest_builds, errors2} <- get_builds(latest_build_as_json),
         %{"count" => count_agents} <- connected_agent_as_json,
         %{"count" => count_queued_builds} <- queued_builds_as_json do
      _ = looping()

      count_builds = Enum.count(running_builds) + Enum.count(latest_builds)

      _ = publish_messages(["#{count_builds} builds retrieved." | errors1 ++ errors2])
      _ = publish_builds(latest_builds, running_builds)
      _ = publish_agents_count(count_agents)
      _ = publish_queued_builds_count(count_queued_builds)

      state
    else
      x ->
        publish_message("An error occured while fetching the builds from Teamcity: #{inspect(x)}")

        _ = looping()

        state
    end
  end

  defp get_builds(%{"build" => builds}) do
    builds
    |> Stream.map(&try_get_build/1)
    |> Enum.reduce({[], []}, &reduce_builds/2)
  end

  defp reduce_builds({:ok, %Build{} = build}, {builds, errors}) when is_list(builds) and is_list(errors) do
    {[build | builds], errors}
  end

  defp reduce_builds({:error, reason}, {builds, errors}) when is_list(builds) and is_list(errors) do
    {builds, [reason | errors]}
  end

  defp try_get_build(%{"id" => _} = build_json) do
    %{
      "id" => id,
      "buildTypeId" => buildTypeId,
      "status" => status,
      "state" => state,
      "webUrl" => url,
      "statusText" => status_text
    } = build_json

    build = %Build{
      id: id,
      name: buildTypeId,
      status: status,
      state: state,
      url: URI.parse(url),
      status_text: status_text
    }

    build =
      Enum.reduce([&try_get_build_date/2, &try_get_branch_name/2, &try_get_start_date/2], build, fn x, acc ->
        x.(acc, build_json)
      end)

    {:ok, build}
  end

  defp try_get_build(raw), do: {:error, "Unknown element received: #{inspect(raw)}"}

  defp try_get_branch_name(%Build{} = build, %{"branchName" => branch}),
    do: %Build{build | branch: branch}

  defp try_get_branch_name(%Build{} = build, _), do: build

  defp try_get_build_date(%Build{} = build, %{"finishDate" => date}),
    do: %Build{build | build_date: Timex.parse!(date, "{ISO:Basic}")}

  defp try_get_build_date(%Build{} = build, _), do: build

  defp try_get_start_date(%Build{} = build, %{"startDate" => date}),
    do: %Build{build | start_date: Timex.parse!(date, "{ISO:Basic}")}

  defp try_get_start_date(%Build{} = build, _), do: build
end
