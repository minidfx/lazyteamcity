defmodule LazyTeamcity.Dashboard.Dashboard do
  @behaviour Ratatouille.App

  alias LazyTeamcity.Build
  alias LazyTeamcity.Dashboard.Helper
  alias LazyTeamcity.Dashboard.LatestBuild
  alias LazyTeamcity.Dashboard.Overlay
  alias LazyTeamcity.Dashboard.RunningBuild
  alias LazyTeamcity.Message
  alias LazyTeamcity.State
  alias LazyTeamcity.TeamcityFetcherServer
  alias LazyTeamcity.TeamcityStateServer

  alias Ratatouille.Runtime.Subscription

  import Ratatouille.View
  import LazyTeamcity.Dashboard.Guards, only: [is_running_build: 1]

  @down_key 65516
  @up_key 65517
  @tab_key 9

  @moduledoc """
  The dashboard!
  """

  @impl true
  def init(context) do
    %{window: %{width: width, height: height}} = context

    model = %State{messages: ["Window size: #{width}x#{height}"], width: width, height: height}

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
      |> Stream.map(fn %Message{datetime: dt, message: x} -> "#{Helper.datetime_to_string(dt)}: #{x}" end)
      |> Stream.concat(existing_messages)
      |> Stream.take(Helper.overlay_size(model))
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
  def update(%State{overlay: false} = model, {:event, %ExTermbox.Event{type: 1, mod: 0, key: @up_key}}) do
    %State{running_builds: rb, latest_builds: lb} = model

    {running_builds, latest_builds} = Stream.concat(rb, lb) |> Enum.reverse() |> select_next() |> split_builds()

    %State{model | build_selected: true}
    |> update_running_builds(running_builds, :skip_selection)
    |> update_latest_builds(latest_builds, :skip_selection)
  end

  @impl true
  def update(%State{overlay: false} = model, {:event, %ExTermbox.Event{type: 1, mod: 0, key: @down_key}}) do
    %State{running_builds: rb, latest_builds: lb} = model

    {running_builds, latest_builds} = Enum.concat(rb, lb) |> select_next() |> split_builds()

    %State{model | build_selected: true}
    |> update_running_builds(running_builds, :skip_selection)
    |> update_latest_builds(latest_builds, :skip_selection)
  end

  @impl true
  def update(%State{} = model, {:event, %ExTermbox.Event{type: 1, mod: 0, key: @tab_key}}) do
    %State{overlay: overlay} = model
    %State{model | overlay: !overlay}
  end

  if(Mix.env() == :dev) do
    @impl true
    def update(%State{} = model, msg) do
      %State{messages: existing_messages} = model
      %State{model | messages: Enum.take([inspect(msg) | existing_messages], Helper.overlay_size(model))}
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
    Subscription.batch([Subscription.interval(500, :tiny_loop), Subscription.interval(1_000, :big_loop)])
  end

  # Private

  defp split_builds(builds) do
    Enum.reduce(builds, {[], []}, fn
      %Build{} = x, {a, b} when is_running_build(x) -> {[x | a], b}
      %Build{} = x, {a, b} -> {a, [x | b]}
    end)
  end

  defp select_next(builds) when is_list(builds) do
    bag = %{was_selected: false, builds: []}
    select_next(builds, bag)
  end

  defp select_next([]) do
    []
  end

  defp select_next([], %{builds: builds}) do
    builds
  end

  defp select_next([%Build{selected: _} = head | tail], %{was_selected: true, builds: builds}) do
    new_bag = %{was_selected: false, builds: [select(head) | builds]}

    select_next(tail, new_bag)
  end

  defp select_next([%Build{selected: true} = head | []], %{was_selected: _, builds: builds}) do
    new_bag = %{was_selected: false, builds: [head | builds]}

    select_next([], new_bag)
  end

  defp select_next([%Build{selected: true} = head | tail], %{was_selected: _, builds: builds}) do
    new_bag = %{was_selected: true, builds: [unselect(head) | builds]}

    select_next(tail, new_bag)
  end

  defp select_next([%Build{selected: _} = head | tail], %{was_selected: _, builds: builds}) do
    new_bag = %{was_selected: false, builds: [head | builds]}

    select_next(tail, new_bag)
  end

  defp is_selected(%Build{selected: x}), do: x

  defp unselect(%Build{} = build), do: %Build{build | selected: false}

  defp select(%Build{} = build), do: %Build{build | selected: true}

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

    %State{model | agents_count: agents, queued_builds_count: queued_builds_count}
    |> update_running_builds(running_builds)
    |> update_latest_builds(latest_builds)
    |> default_select_first()
  end

  defp update_running_builds(%State{} = model, new_running_builds, :skip_selection) do
    running_builds =
      new_running_builds
      |> Stream.take(RunningBuild.get_lines_available(model))
      |> Enum.sort_by(&Helper.sort_by_date/1, :desc)

    %State{model | running_builds: running_builds}
    |> update_build_selected(running_builds)
  end

  defp update_running_builds(%State{running_builds: rb} = model, new_running_builds) do
    builds_by_id = Map.new(rb, fn %Build{id: x} = b -> {x, b} end)

    running_builds =
      new_running_builds
      |> Stream.take(RunningBuild.get_lines_available(model))
      |> Stream.map(&try_update_selection(&1, builds_by_id))
      |> Enum.sort_by(&Helper.sort_by_date/1, :desc)

    %State{model | running_builds: running_builds}
    |> update_build_selected(running_builds)
  end

  defp update_latest_builds(%State{} = model, new_latest_builds, :skip_selection) do
    latest_builds =
      new_latest_builds
      |> Stream.take(LatestBuild.get_lines_available(model))
      |> Enum.sort_by(&Helper.sort_by_date/1, :desc)

    %State{model | latest_builds: latest_builds}
    |> update_build_selected(latest_builds)
  end

  defp update_latest_builds(%State{latest_builds: lb} = model, new_latest_builds) do
    builds_by_id = Map.new(lb, fn %Build{id: x} = b -> {x, b} end)

    latest_builds =
      new_latest_builds
      |> Stream.take(LatestBuild.get_lines_available(model))
      |> Stream.map(&try_update_selection(&1, builds_by_id))
      |> Enum.sort_by(&Helper.sort_by_date/1, :desc)

    %State{model | latest_builds: latest_builds}
    |> update_build_selected(latest_builds)
  end

  defp update_build_selected(%State{} = model, builds) when is_list(builds) do
    %State{
      model
      | build_selected:
          match?(%State{build_selected: true}, model) and
            Stream.filter(builds, &is_selected/1) |> Enum.any?()
    }
  end

  defp default_select_first(%State{build_selected: true} = model) do
    model
  end

  defp default_select_first(%State{running_builds: [], latest_builds: []} = model) do
    %State{model | build_selected: false}
  end

  defp default_select_first(%State{build_selected: false, running_builds: rb} = model)
       when length(rb) > 0 do
    [head | tail] = rb
    any_builds_selected = Enum.any?(rb, fn %Build{selected: x} -> x end)

    if(any_builds_selected, do: model, else: %State{model | running_builds: [select(head) | tail]})
  end

  defp default_select_first(%State{build_selected: false, latest_builds: lb} = model)
       when length(lb) > 0 do
    [head | tail] = lb
    any_builds_selected = Enum.any?(lb, fn %Build{selected: x} -> x end)

    if(any_builds_selected, do: model, else: %State{model | latest_builds: [select(head) | tail]})
  end

  defp try_update_selection(%Build{id: id} = build, %{} = builds_by_id) do
    with {:ok, %Build{selected: previous_selection}} <- Map.fetch(builds_by_id, id) do
      %Build{build | selected: previous_selection}
    else
      _ -> build
    end
  end
end
