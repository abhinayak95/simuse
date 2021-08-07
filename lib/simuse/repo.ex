defmodule Simuse.Repo do
  use Ecto.Repo,
    otp_app: :simuse,
    adapter: Ecto.Adapters.Postgres
end
