defmodule LazyTeamcity.TeamcityHttpClient do
  use Tesla

  plug(Tesla.Middleware.Headers, [{"Accept", "application/json"}])
  plug(Tesla.Middleware.BaseUrl, teamcity_uri())
  plug(Tesla.Middleware.BearerAuth, token: Application.fetch_env!(:lazy_teamcity, :teamcity_token))
  plug(Tesla.Middleware.FollowRedirects)
  plug(Tesla.Middleware.Retry)
  plug(Tesla.Middleware.PathParams)
  plug(Tesla.Middleware.JSON)

  @spec try_get_running_builds(integer()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def try_get_running_builds(count) when is_integer(count) and count > 0 do
    get("/app/rest/builds",
      query: [
        locator: "state:running,count:#{count},start:0",
        fields: "build(id,buildTypeId,status,state,webUrl,statusText,startDate,branchName)"
      ]
    )
  end

  @spec try_get_latest_builds(integer()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def try_get_latest_builds(count) when is_integer(count) and count > 0 do
    get("/app/rest/builds",
      query: [
        defaultFilter: false,
        locator: "count:#{count},start:0,running:false,canceled:false",
        fields: "build(id,buildTypeId,status,state,webUrl,statusText,finishDate,branchName)",
        order: "order:finishDate"
      ]
    )
  end

  @spec try_get_connected_agents() :: {:error, any()} | {:ok, Tesla.Env.t()}
  def try_get_connected_agents() do
    get("/app/rest/agents", query: [locator: "connected:true,authorized:true"])
  end

  @spec try_get_queued_builds_count() :: {:error, any()} | {:ok, Tesla.Env.t()}
  def try_get_queued_builds_count() do
    get("/app/rest/buildQueue", query: [defaultFilter: false, fields: "count"])
  end

  # Private

  defp teamcity_uri() do
    scheme = if(Application.fetch_env!(:lazy_teamcity, :secure), do: "https", else: "http")
    host = Application.fetch_env!(:lazy_teamcity, :hostname)

    "#{scheme}://#{host}"
  end
end
