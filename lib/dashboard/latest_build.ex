defmodule LazyTeamcity.Dashboard.LatestBuild do
  use LazyTeamcity.Dashboard.Global

  @behaviour LazyTeamcity.Dashboard.Components

  alias LazyTeamcity.Build
  alias LazyTeamcity.State

  @impl true
  def show(%State{overlay: true, height: height}) when full_screen(height), do: false
  def show(%State{overlay: _}), do: true

  @impl true
  def draw(%State{latest_builds: []} = model) do
    panel(title: " \uf14a Latest builds ", height: compute_latest_build_height(model)) do
      label([text(content: "No builds")])
    end
  end

  @impl true
  def draw(%State{latest_builds: builds} = model) do
    panel(title: " \uf14a Latest builds ", height: compute_latest_build_height(model)) do
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

      builds
      |> Enum.sort_by(fn %Build{build_date: x} -> x end, :desc)
      |> Enum.map(&draw_row(model, &1))
    end
  end

  @spec compute_latest_build_height(State.t()) :: non_neg_integer()
  def compute_latest_build_height(%State{height: x}), do: div(x, 2) - 1

  @spec get_lines_available(State.t()) :: non_neg_integer()
  def get_lines_available(%State{} = model), do: compute_latest_build_height(model) - 5

  defp draw_row(%State{} = model, %Build{build_date: date} = build) when not is_nil(date) do
    row do
      yield_column(model, 3, datetime_to_string(date), to_color(build))
      yield_column(model, 1, trim_branch(build), to_color(build))
      yield_column(model, 3, build.name, to_color(build))
      yield_column(model, 5, build.status_text || "no-status", to_color(build))
    end
  end
end
