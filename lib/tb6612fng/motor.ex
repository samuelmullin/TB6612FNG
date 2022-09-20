defmodule TB6612FNG.Motor do
  @moduledoc"""
  Controls a motor attached to the TB6612FNG.  Has a number of required settings:

  - `in01_pin` - A GPIO pin number for the first input pin for this motor
  - `in02_pin` - A GPIO pin number for the second input pin for this motor
  - `pwm_pin` - A GPIO pin number for the PWM pin for this motor.  **Must be a hardware PWM pin.**
  - `name` - A unique atom that will be used as both the ID and name of the GenServer controlling this motor.  Used to control the motor from elsewhere.
  """

  use GenServer

  alias Circuits.GPIO
  alias Pigpiox.Pwm
  alias __MODULE__

  @frequency 800

  defstruct in01_ref: 0,
            in02_ref: 0,
            pwm_pin: 0,
            name: "",
            output: 0

  def child_spec(opts) do
    %{
      id: Keyword.fetch!(opts, :name),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc"""
  Set the direction of rotation and output for the motor specified.

  Accepts three parameters:

  - `name` - The name (atom) of the GenServer controlling the motor.
  - `direction` - Either `:cw` for clockwise or `:ccw` for counter-clockwise rotation
  - `output` - The PWM output requested.  This should be an integer value between 0 and 1_000_000
  """
  def set_output(name, direction, output)
    when direction in [:cw, :ccw] and is_integer(output) and output >= 0 and output <= 1_000_000 do
    GenServer.cast(name, {:drive, direction, output})
  end

  @doc"""
  Short brake the motor.  This sets the output to 0.
  """
  def short_brake(name)  do
    GenServer.cast(name, :stort_brake)
  end

  @doc"""
  Stop the motor.  This leaves the PWM pin set at the current rate but sets both input pins low.
  """
  def stop(name) do
    GenServer.cast(name, :stop)
  end

  @doc"""
  Return the config for the motor, mostly for troubleshooting purposes or running manual commands using the GPIO references.
  """
  def get_config(name) do
    GenServer.call(name, :get_config)
  end

  # --- Callbacks ---
  @impl true
  def init(opts) do
    in01_pin = Keyword.fetch!(opts, :in01_pin)
    in02_pin = Keyword.fetch!(opts, :in02_pin)
    pwm_pin = Keyword.fetch!(opts, :pwm_pin)
    name = Keyword.fetch!(opts, :name)

    {:ok, in01_ref} = GPIO.open(in01_pin, :output, initial_value: 0)
    {:ok, in02_ref} = GPIO.open(in02_pin, :output, initial_value: 0)

    motor_config = %Motor{
      in01_ref: in01_ref,
      in02_ref: in02_ref,
      pwm_pin: pwm_pin,
      name: name
    }

    {:ok, motor_config}
  end

  @impl true
  def handle_call(:get_config, _from, config) do
    {:reply, config, config}
  end

  @impl true
  def handle_cast({:drive, direction, output}, config) do
    {:noreply, change_output(direction, output, config)}
  end

  @impl true
  def handle_cast(:short_brake, config) do
    Pwm.hardware_pwm(config.pwm_pin, @frequency, 0)
    {:noreply, struct(config, [output: 0])}
  end

  @impl true
  def handle_cast(:stop, config) do
    GPIO.write(config.in01_ref, 0)
    GPIO.write(config.in02_ref, 0)
    {:noreply, config}
  end

  defp change_output(:cw, output, config) do
    GPIO.write(config.in01_ref, 1)
    GPIO.write(config.in02_ref, 0)
    Pwm.hardware_pwm(config.pwm_pin, @frequency, output)
    struct(config, [output: output])
  end

  defp change_output(:ccw, output, config) do
    GPIO.write(config.in01_ref, 0)
    GPIO.write(config.in02_ref, 1)
    Pwm.hardware_pwm(config.pwm_pin, @frequency, output)
    struct(config, [output: output])
  end

end
