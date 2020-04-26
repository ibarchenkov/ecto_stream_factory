defmodule EctoStreamFactory.Repo do
  use Ecto.Repo,
    otp_app: :ecto_stream_factory,
    adapter: Ecto.Adapters.Postgres
end
