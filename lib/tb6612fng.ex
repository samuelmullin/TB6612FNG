defmodule TB6612FNG do
  use Supervisor

  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, [])
  end

  def init(opts) do
    [{TB6612FNG.Module, opts}]
    |> append_motor(Keyword.get(opts, :motor_a))
    |> append_motor(Keyword.get(opts, :motor_b))
    |> Supervisor.init(strategy: :one_for_one)
  end

  def append_motor(children, nil), do: children
  def append_motor(children, motor), do: [{TB6612FNG.Motor, motor} | children]

end
