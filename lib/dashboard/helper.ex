defmodule LazyTeamcity.Dashboard.Helper do
  alias LazyTeamcity.Build
  alias LazyTeamcity.State

  import Ratatouille.View
  import LazyTeamcity.Dashboard.Guards, only: [full_screen: 1]

  @spec sort_by_date(Build.t()) :: boolean()
  def sort_by_date(%Build{build_date: x, start_date: y}) when is_nil(x), do: y
  def sort_by_date(%Build{build_date: x}), do: x

  @spec column_size(State.t()) :: integer()
  def column_size(%State{width: width}), do: div(width, 12)

  @spec to_color(Build.t()) :: :green | :magenta | :red | :default
  def to_color(%Build{status: "SUCCESS"}), do: :green
  def to_color(%Build{status: "FAILURE"}), do: :red
  def to_color(%Build{status: "UNKNOWN"}), do: :magenta
  def to_color(%Build{status: _}), do: :default

  @spec truncate_string(State.t(), integer(), String.t()) :: String.t()
  def truncate_string(%State{} = model, columns, text) when is_integer(columns) and is_bitstring(text) do
    String.slice(text, 0, column_size(model) * columns - 1)
  end

  @spec datetime_to_string(DateTime.t()) :: String.t()
  def datetime_to_string(%DateTime{} = dt) do
    dt
    |> Timex.to_datetime(Application.fetch_env!(:lazy_teamcity, :timezone))
    |> Timex.format!("{ISOdate} {h24}:{m}:{s}")
  end

  @spec overlay_size(State.t()) :: integer()
  def overlay_size(%State{height: height}) when full_screen(height), do: height
  def overlay_size(%State{height: height}), do: div(height, 3) + 2

  @spec trim_branch(Build.t()) :: String.t()
  def trim_branch(%Build{branch: branch}) when is_bitstring(branch),
    do: String.replace_prefix(branch, "refs/heads/", "")

  @spec trim_branch(Build.t()) :: String.t()
  def trim_branch(%Build{}), do: "no-branch"

  @spec yield_selected_column(State.t(), size :: non_neg_integer(), text :: String.t()) ::
          Ratatouille.Renderer.Element.t()
  def yield_selected_column(%State{} = model, size, text) when is_integer(size) and is_bitstring(text) do
    column(size: size) do
      label(background: :white, color: :black) do
        text(content: truncate_string(model, size, text))
      end
    end
  end

  @spec yield_column(
          State.t(),
          size :: non_neg_integer(),
          text :: String.t(),
          color :: :green | :red | :magenta | :default
        ) :: Ratatouille.Renderer.Element.t()
  def yield_column(%State{} = model, size, text, color \\ :default)
      when is_integer(size) and is_bitstring(text) and color in [:green, :red, :magenta, :default] do
    column(size: size) do
      label do
        case color do
          :default -> text(content: truncate_string(model, size, text))
          x -> text(content: truncate_string(model, size, text), color: x)
        end
      end
    end
  end
end
