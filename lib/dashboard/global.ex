defmodule LazyTeamcity.Dashboard.Global do
  alias LazyTeamcity.Build
  alias LazyTeamcity.State

  defmacro __using__(_opts) do
    quote do
      defmacrop full_screen(height) do
        quote do
          div(unquote(height), 3) < 10
        end
      end

      import Ratatouille.View

      defp column_size(%State{width: width}), do: div(width, 12)

      @spec to_color(Build.t()) :: :green | :magenta | :red | :default
      defp to_color(%Build{status: "SUCCESS"}), do: :green
      defp to_color(%Build{status: "FAILURE"}), do: :red
      defp to_color(%Build{status: "UNKNOWN"}), do: :magenta
      defp to_color(%Build{status: _}), do: :default

      @spec truncate_string(State.t(), integer(), String.t()) :: String.t()
      defp truncate_string(%State{width: width} = model, columns, text)
           when is_integer(columns) and is_bitstring(text) do
        String.slice(text, 0, column_size(model) * columns - 1)
      end

      @spec datetime_to_string(DateTime.t()) :: String.t()
      defp datetime_to_string(%DateTime{} = dt) do
        dt
        |> Timex.to_datetime(Application.fetch_env!(:lazy_teamcity, :timezone))
        |> Timex.format!("{ISOdate} {h24}:{m}:{s}")
      end

      @spec overlay_size(State.t()) :: integer()
      defp overlay_size(%State{height: height}) when full_screen(height), do: height
      defp overlay_size(%State{height: height}), do: div(height, 3) + 2

      @spec trim_branch(Build.t()) :: String.t()
      defp trim_branch(%Build{branch: branch}) when is_bitstring(branch),
        do: String.replace_prefix(branch, "refs/heads/", "")

      @spec trim_branch(Build.t()) :: String.t()
      defp trim_branch(%Build{}), do: "no-branch"

      @spec yield_column(
              State.t(),
              size :: non_neg_integer(),
              text :: String.t(),
              color :: :green | :red | :magenta | :default
            ) ::
              Ratatouille.Renderer.Element.t()
      defp yield_column(%State{} = model, size, text, color \\ :default)
           when is_integer(size) and
                  is_bitstring(text) and
                  color in [:green, :red, :magenta, :default] do
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
  end
end
