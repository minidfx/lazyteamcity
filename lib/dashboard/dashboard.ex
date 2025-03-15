defmodule LazyTeamcity.Dashboard.Dashboard do
  use LazyTeamcity.Dashboard.Global

  @behaviour Ratatouille.App

  alias LazyTeamcity.Dashboard.LatestBuild
  alias LazyTeamcity.Dashboard.Overlay
  alias LazyTeamcity.Dashboard.RunningBuild
  alias LazyTeamcity.Message
  alias LazyTeamcity.State
  alias LazyTeamcity.TeamcityFetcherServer
  alias LazyTeamcity.TeamcityStateServer
  alias Ratatouille.Runtime.Subscription

  @moduledoc """
  The dashboard!
  """

  @impl true
  def init(context) do
    %{window: %{width: width, height: height}} = context

    model = %State{
      messages: ["Window size: #{width}x#{height}"],
      width: width,
      height: height
    }

    TeamcityFetcherServer.update_count_latest_builds_messages(LatestBuild.get_lines_available(model))
    TeamcityFetcherServer.update_count_running_builds_messages(RunningBuild.get_lines_available(model))

    model
  end

  @impl true
  def update(%State{} = model, :big_loop), do: update_teamcity(model)

  @impl true
  def update(%State{} = model, :tiny_loop) do
    %State{messages: existing_messages} = model

    messages =
      TeamcityStateServer.get_messages()
      |> Stream.map(fn %Message{datetime: dt, message: x} -> "#{datetime_to_string(dt)}: #{x}" end)
      |> Stream.concat(existing_messages)
      |> Stream.take(overlay_size(model))
      |> Enum.to_list()

    %State{model | messages: messages}
  end

  @impl true
  def update(%State{} = model, {:resize, event}) do
    %State{messages: existing_messages} = model
    %ExTermbox.Event{type: _, mod: 0, key: 0, ch: 0, w: width, h: height, x: 0, y: 0} = event

    TeamcityFetcherServer.update_count_latest_builds_messages(LatestBuild.get_lines_available(model))
    TeamcityFetcherServer.update_count_running_builds_messages(RunningBuild.get_lines_available(model))

    update_teamcity(%State{model | width: width, height: height, messages: [inspect(event) | existing_messages]})
  end

  @impl true
  def update(%State{} = model, {:event, %ExTermbox.Event{type: 1, mod: 0, key: 9}}) do
    %State{overlay: overlay} = model
    %State{model | overlay: !overlay}
  end

  if(Mix.env() == :dev) do
    @impl true
    def update(%State{} = model, msg) do
      %State{messages: existing_messages} = model
      %State{model | messages: Enum.take([inspect(msg) | existing_messages], overlay_size(model))}
    end
  else
    @impl true
    def update(%State{} = model, _msg) do
      model
    end
  end

  @impl true
  def render(model), do: view([bottom_bar: status_bar(model)], yield_root_components(model))

  @impl true
  def subscribe(_model) do
    Subscription.batch([
      Subscription.interval(500, :tiny_loop),
      Subscription.interval(1_000, :big_loop)
    ])
  end

  # Private

  defp status_bar(%State{} = model) do
    %State{agents_count: agents, queued_builds_count: queued} = model

    bar do
      label(content: "Queued: #{queued} Agents: #{agents}")
    end
  end

  defp yield_root_components(%State{} = model) do
    [RunningBuild, LatestBuild, Overlay]
    |> Stream.filter(fn x -> x.show(model) end)
    |> Enum.map(fn x -> x.draw(model) end)
  end

  defp update_teamcity(%State{} = model) do
    {latest_builds, running_builds, queued_builds_count} = TeamcityStateServer.get_builds()
    %LazyTeamcity.Stats{count_agents: agents} = TeamcityStateServer.get_stats()

    %State{
      model
      | running_builds: running_builds |> Enum.reverse() |> Enum.take(RunningBuild.get_lines_available(model)),
        latest_builds: latest_builds |> Enum.reverse() |> Enum.take(LatestBuild.get_lines_available(model)),
        agents_count: agents,
        queued_builds_count: queued_builds_count
    }
  end
end
