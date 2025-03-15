defmodule LazyTeamcity.Application do
  use Application

  @spec start(any(), any()) :: {:error, any()} | {:ok, pid()}
  def start(_type, _args) do
    children = [
      LazyTeamcity.TeamcityStateServer,
      LazyTeamcity.TeamcityFetcherServer,
      {Finch, name: LazyTeamcity.Finch, pools: %{:default => [size: 10]}},
      {Ratatouille.Runtime.Supervisor,
       runtime: [app: LazyTeamcity.Dashboard.Dashboard, quit_events: [{:key, Ratatouille.Constants.key(:ctrl_c)}]]}
      # other workers...
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: LazyTeamcity.Supervisor)
  end
end
