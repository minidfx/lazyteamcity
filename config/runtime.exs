import Config

if(Mix.env() == :prod) do
  config :lazy_teamcity,
    teamcity_token: System.get_env("ACCESS_TOKEN") || raise("The ACCESS_TOKEN was missing."),
    timezone: System.get_env("TIMEZONE") || raise("The TIMEZONE was missing."),
    fetcher_interval_seconds: System.get_env("INTERVAL") || 10_000,
    hostname: System.get_env("HOST") || raise("The HOST was missing."),
    secure: System.get_env("SECURE") || true
end
