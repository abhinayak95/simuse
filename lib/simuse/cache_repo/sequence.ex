defmodule Simuse.CacheRepo.Sequence do
  use GenServer

  def initialize(model), do: GenServer.start_link(__MODULE__, 0, name: model)

  def init(initial_count), do: {:ok, initial_count}

  def get(model), do: GenServer.call(model, :get)

  def handle_call(:get, _, count), do: {:reply, count + 1, count + 1}
end
