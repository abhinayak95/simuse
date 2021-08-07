defmodule Simuse.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :age, :integer
    field :first_name, :string
    field :last_name, :string
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :first_name, :last_name, :age])
    |> validate_required([:username, :first_name, :last_name, :age])
    |> unique_constraint(:username)
  end
end
