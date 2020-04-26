import Config

config :ecto_stream_factory, ecto_repos: [EctoStreamFactory.Repo]

config :ecto_stream_factory, EctoStreamFactory.Repo,
  hostname: "localhost",
  database: "ecto_stream_factory_test",
  username: "postgres",
  password: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :info
