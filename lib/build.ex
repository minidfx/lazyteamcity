defmodule LazyTeamcity.Build do
  use GuardedStruct

  @moduledoc """
  Model representing a teamcity build.
  """

  guardedstruct do
    # Required
    field(:id, String.t(), enforce: true)
    field(:name, String.t(), enforce: true)
    field(:status, String.t(), enforce: true)
    field(:state, String.t(), enforce: true)
    field(:url, URI.t(), enforce: true)

    # Optional
    field(:build_date, DateTime.t(), enforce: false)
    field(:start_date, DateTime.t(), enforce: false)
    field(:status_text, String.t(), enforce: false)
    field(:branch, String.t(), enforce: false)
    field(:selected, boolean(), default: false)
  end
end
