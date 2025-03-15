defmodule LazyTeamcity.Dashboard.Guards do
  alias LazyTeamcity.State
  alias LazyTeamcity.Build

  defguard full_screen(state)
           when is_struct(state, State) and
                  is_map_key(state, :height) and
                  div(state.height, 3) < 10

  defguard is_running_build(build)
           when is_struct(build, Build) and
                  is_map_key(build, :build_date) and
                  is_map_key(build, :start_date) and
                  is_nil(build.build_date) and
                  not is_nil(build.start_date)
end
