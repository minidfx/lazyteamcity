defmodule LazyTeamcity.TeamcityFetcherState do
  use GuardedStruct

  guardedstruct do
    field(:count_latest_build, non_neg_integer(), default: 50)
    field(:count_running_build, non_neg_integer(), default: 50)
  end
end
