defmodule LazyTeamcity.State do
  use GuardedStruct

  alias LazyTeamcity.Build

  guardedstruct do
    field(:messages, list(String.t()), defaut: [])
    field(:running_builds, list(Build.t()), default: [])
    field(:latest_builds, list(Build.t()), default: [])
    field(:agents_count, integer(), default: 0)
    field(:queued_builds_count, integer(), default: 0)
    field(:width, integer(), enforce: true)
    field(:height, integer(), enforce: true)
    field(:overlay, boolean(), default: false)
    field(:build_selected, boolean(), default: false)
  end
end
