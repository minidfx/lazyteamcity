defmodule LazyTeamcity.Message do
  use GuardedStruct

  guardedstruct do
    field(:datetime, DateTime.t(), enforce: true)
    field(:message, String.t(), enforce: true)
  end
end
