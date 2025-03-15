defmodule LazyTeamcity.Dashboard.Overlay do
  @behaviour LazyTeamcity.Dashboard.Components

  use LazyTeamcity.Dashboard.Global

  alias LazyTeamcity.State

  @impl true
  def show(%State{overlay: true}), do: true
  def show(%State{overlay: false}), do: false

  @impl true
  @spec draw(LazyTeamcity.State.t()) :: Ratatouille.Renderer.Element.t()
  def draw(%State{height: height} = model) when not full_screen(height) do
    %State{messages: messages} = model

    overlay do
      panel(
        [
          title: " \ueb9b Console ",
          height: :fill
        ],
        messages
        |> Stream.map(&truncate_string(model, 10, &1))
        |> Stream.map(fn x -> text(content: x) end)
        |> Enum.map(fn x -> label([x]) end)
      )
    end
  end

  def draw(%State{} = model) do
    %State{messages: messages} = model

    panel(
      [
        title: " \ueb9b Console ",
        height: :fill
      ],
      messages
      |> Stream.map(&truncate_string(model, 10, &1))
      |> Stream.map(fn x -> text(content: x) end)
      |> Enum.map(fn x -> label([x]) end)
    )
  end
end
