defmodule LazyTeamcity.Dashboard.RunningBuild do
  @behaviour LazyTeamcity.Dashboard.Components

  import Ratatouille.View
  import LazyTeamcity.Dashboard.Guards, only: [full_screen: 1]

  alias LazyTeamcity.Build
  alias LazyTeamcity.Dashboard.Helper
  alias LazyTeamcity.State

  @impl true
  def show(%State{overlay: true} = state) when full_screen(state), do: false
  def show(%State{overlay: _}), do: true

  @impl true
  def draw(%State{running_builds: []} = model) do
    panel(
      title: " \uf04b Running builds ",
      height: compute_running_build_height(model)
    ) do
      label([text(content: "No builds")])
    end
  end

  @impl true
  def draw(%State{running_builds: builds} = model) do
    panel(
      title: " \uf04b Running builds ",
      height: compute_running_build_height(model)
    ) do
      row do
        column(size: 3) do
          label([text(content: "Date")])
        end

        column(size: 1) do
          label([text(content: "Branch")])
        end

        column(size: 3) do
          label([text(content: "Name")])
        end

        column(size: 5) do
          label([text(content: "Status")])
        end
      end

      Enum.map(builds, &draw_row(model, &1))
    end
  end

  @spec compute_running_build_height(LazyTeamcity.State.t()) :: integer()
  def compute_running_build_height(%State{height: x}), do: ceil(x / 2)

  @spec get_lines_available(State.t()) :: non_neg_integer()
  def get_lines_available(%State{} = model), do: compute_running_build_height(model) - 5

  # Private

  defp draw_row(%State{} = model, %Build{start_date: date, selected: true} = build) when not is_nil(date) do
    row do
      Helper.yield_selected_column(model, 3, Helper.datetime_to_string(date))
      Helper.yield_selected_column(model, 1, Helper.trim_branch(build))
      Helper.yield_selected_column(model, 3, build.name)
      Helper.yield_selected_column(model, 5, build.status_text || "no-status")
    end
  end

  defp draw_row(%State{} = model, %Build{start_date: date} = build) when not is_nil(date) do
    row do
      Helper.yield_column(model, 3, Helper.datetime_to_string(date))
      Helper.yield_column(model, 1, Helper.trim_branch(build))
      Helper.yield_column(model, 3, build.name)
      Helper.yield_column(model, 5, build.status_text || "no-status")
    end
  end
end
