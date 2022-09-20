defmodule TB6612FNG.Module do
  @moduledoc """
  Driver for TB6612FNG Module.

  [Data Sheet](https://www.sparkfun.com/datasheets/Robotics/TB6612FNG.pdf)
  """

  use GenServer

  alias Circuits.GPIO
  alias TB6612FNG.Motor

  defmodule Config do
    defstruct standby_ref: 0,
              name: __MODULE__
  end

  # --- Public API ---

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(config) do
    name = Keyword.get(config, :name, __MODULE__)
    GenServer.start_link(__MODULE__, config, name: name)
  end

  @doc"""
  Sets the output of the specified motor in a specific direction.

  Accepts three parameters:

  - `name` - The name (atom) of the GenServer controlling the motor.
  - `direction` - Either `:cw` for clockwise or `:ccw` for counter-clockwise rotation
  - `output` - The PWM output requested.  This should be an integer value between 0 and 1_000_000
  """
  def set_output(motor, direction, output)
    when direction in [:cw, :ccw] and is_integer(output) and output >= 0 and output <= 1_000_000 do
    Motor.set_output(motor, direction, output)
  end

  @doc"""
  Returns the config of the module.  Mostly used for troubleshooting/accessing the standby reference directly.
  """
  def get_config(name), do: GenServer.call({:local, name}, :get_config)

  @doc"""
  Sets the standby pin to low.  Will stop both motors if they are currently turning, but will retain
  whatever settings they had set, so if standby mode is disabled, they will start again.  Standby mode
  is a high impedance/low power mode.
  """
  def enable_standby(name \\ __MODULE__), do: GenServer.cast(name, {:set_standby, 0})

  @doc"""
  Sets the standby pin to high, disabling Standby mode.
  """
  def disable_standby(name \\ __MODULE__), do: GenServer.cast(name, {:set_standby, 1})

  @impl true
  def init(opts) do
    standby_pin = Keyword.fetch!(opts, :standby_pin)
    {:ok, standby_ref} = GPIO.open(standby_pin, :output)
    {:ok, struct(%Config{}, Keyword.put(opts, :standby_ref, standby_ref))}
  end

  @impl true
  def handle_cast({:set_standby, value}, config) do
    GPIO.write(config.standby_ref, value)
    {:noreply, config}
  end

  @impl true
  def handle_call(:get_config, _from, config) do
    {:reply, config, config}
  end

end
