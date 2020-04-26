{:ok, _pid} = EctoStreamFactory.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(EctoStreamFactory.Repo, :manual)

ExUnit.start()
