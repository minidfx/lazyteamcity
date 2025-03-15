defmodule LazyTeamcity.Dashboard.Overlay do
  @behaviour LazyTeamcity.Dashboard.Components

  alias LazyTeamcity.Dashboard.Helper
  alias LazyTeamcity.State

  import Ratatouille.View
  import LazyTeamcity.Dashboard.Guards, only: [full_screen: 1]

  @impl true
  def show(%State{overlay: true}), do: true
  def show(%State{overlay: false}), do: false

  @impl true
  @spec draw(LazyTeamcity.State.t()) :: Ratatouille.Renderer.Element.t()
  def draw(%State{} = model) when not full_screen(model) do
    %State{messages: messages} = model

    overlay do
      panel(
        [title: " \ueb9b Console ", height: :fill],
        messages
        |> Stream.map(&Helper.truncate_string(model, 10, &1))
        |> Stream.map(fn x -> text(content: x) end)
        |> Enum.map(fn x -> label([x]) end)
      )
    end
  end

  def draw(%State{} = model) do
    %State{messages: messages} = model

    panel(
      [title: " \ueb9b Console ", height: :fill],
      messages
      |> Stream.map(&Helper.truncate_string(model, 10, &1))
      |> Stream.map(fn x -> text(content: x) end)
      |> Enum.map(fn x -> label([x]) end)
    )
  end
end
