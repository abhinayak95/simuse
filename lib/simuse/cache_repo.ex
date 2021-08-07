defmodule Simuse.CacheRepo do
  use GenServer

  import Ecto.Query

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    [Simuse.Accounts.User]
    |> Enum.each(
      fn model ->
        source = get_source(model)

        :ets.new(
          source,
          [:public, :named_table, write_concurrency: true, read_concurrency: true]
        )

        __MODULE__.Sequence.initialize(source)
      end
    )

    {:ok, nil}
  end

  def all(model) do
    :ets.tab2list(get_source(model))
    |> Enum.map(fn {_id, record} -> record end)
  end

  def get!(model, id) when is_binary(id) do
    get!(model, String.to_integer(id))
  end
  def get!(model, id) do
    case :ets.lookup(get_source(model), id) do
      [{_, record}] ->
        record

      _ ->
        raise Ecto.NoResultsError, queryable: (from q in model, where: q.id == ^id)
    end
  end

  def insert(%Ecto.Changeset{valid?: true, data: data} = changeset) do
    case process_constraints(changeset) do
      %Ecto.Changeset{valid?: true} ->

      case Ecto.Changeset.apply_action(changeset, :insert) do
        {:ok, record} ->
          source = get_source(data)
          id = __MODULE__.Sequence.get(source)

          record_with_id =
            record
            |> Map.put(:id, id)

          case :ets.insert(source, {id, record_with_id}) do
            true ->
              {:ok, record_with_id}

            false ->
              {:error, :error}
          end

        {:error, changeset} ->
          {:error, changeset}
      end

      changeset ->
        {:error, changeset}
    end
  end
  def insert(changeset) do
    Ecto.Changeset.apply_action(changeset, :insert)
  end

  def update(%Ecto.Changeset{valid?: true, data: %{id: id} = data} = changeset) do
    case process_constraints(changeset) do
      %Ecto.Changeset{valid?: true} ->
        case Ecto.Changeset.apply_action(changeset, :insert) do
          {:ok, record} ->
            source = get_source(data)

            case :ets.insert(source, {id, record}) do
              true ->
                {:ok, record}

              false ->
                {:error, :error}
            end

          {:error, changeset} ->
            {:error, changeset}
        end

        changeset ->
          {:error, changeset}
    end
  end
  def update(changeset) do
    Ecto.Changeset.apply_action(changeset, :update)
  end

  def delete(%{id: id} = record) do
    case :ets.delete(get_source(record), id) do
      true ->
        {:ok, record}

      false ->
        {:error, :error}
    end
  end

  defp get_source(model) do
    struct(model, %{}).__meta__.source()
    |> String.to_atom()
  end

  defp process_constraints(%Ecto.Changeset{constraints: []} = changeset), do: changeset
  defp process_constraints(%Ecto.Changeset{constraints: constraints, changes: changes, data: data} = changeset) do
    constraints
    |> Enum.reduce(
      changeset,
      fn
        %{type: :unique, field: field, error_message: error_message}, changeset ->
          exists? =
            all(data)
            |> Enum.find(
              fn
                record ->
                  changes_field = changes[field]
                  data_id = data.id

                  case record do
                    %{^field => ^changes_field, id: id} when id != data_id ->
                      true

                    _ ->
                      false
                  end
              end
            )

          if exists? do
            Ecto.Changeset.add_error(
              changeset,
              field,
              error_message
            )
          else
            changeset
          end
        _, changeset ->

          changeset
      end
    )
  end
end
