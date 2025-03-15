defmodule LazyTeamcity.Dashboard.Components do
  alias LazyTeamcity.State

  @callback show(State.t()) :: boolean()
  @callback draw(LazyTeamcity.State.t()) :: Ratatouille.Renderer.Element.t()
end
