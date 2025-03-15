defmodule LazyTeamcity.Stats do
  use GuardedStruct

  guardedstruct do
    field(:count_agents, integer(), enforce: true)
  end
end
