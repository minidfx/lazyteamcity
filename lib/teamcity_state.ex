defmodule LazyTeamcity.TeamcityState do
  use GuardedStruct

  alias LazyTeamcity.Build
  alias LazyTeamcity.Message

  guardedstruct do
    field(:running_builds, list(Build.t()), default: [])
    field(:latest_builds, list(Build.t()), default: [])
    field(:queued_builds_count, non_neg_integer(), default: 0)
    field(:messages, list(Message.t()), default: [])
    field(:agents, non_neg_integer(), default: 0)
  end
end
