defmodule Entice.Area do

  defmacro __using__(_) do
    quote do
      alias Entice.Area.HeroesAscent
      alias Entice.Area.RandomArenas
      alias Entice.Area.TeamArenas
    end
  end

  defmodule Map do
    @moduledoc """
    This macro puts all common map functions inside the module that uses it
    """

    defmacro __using__(_) do
      quote do
        # Define the module content
        alias Entice.Area.Geom.Coord

        def name, do: __MODULE__
        def spawn, do: %Coord{}

        defoverridable [name: 0, spawn: 0]

        # Define an event manager
        evt_name = Module.concat(__MODULE__, "Evt")
        evt_contents = quote do
          def start_link, do: GenEvent.start_link([name: unquote(evt_name)])
        end

        Module.create(evt_name, evt_contents, Macro.Env.location(__ENV__))


        # Define a supervisor
        sup_name = Module.concat(__MODULE__, "Sup")
        sup_contents = quote do
          use Supervisor

          def start_link, do: Supervisor.start_link(unquote(sup_name), :ok)

          def init(:ok) do
            children = [
              worker(unquote(evt_name), []),
              supervisor(Entice.Area.Entity.Sup, [unquote(__MODULE__)])
            ]
            supervise(children, strategy: :one_for_one)
          end
        end

        Module.create(sup_name, sup_contents, Macro.Env.location(__ENV__))
      end
    end
  end


  defmodule HeroesAscent, do: use Map
  defmodule RandomArenas, do: use Map
  defmodule TeamArenas,   do: use Map


  @doc """
  Simplistic map getter, tries to convert a map name to the module atom.
  The map should be a GW map name, without "Entice.Area.Worlds"
  """
  def get_map(name) do
    try do
      {:ok, ((__MODULE__ |> Atom.to_string) <> "." <> name) |> String.to_existing_atom}
    rescue
      ArgumentError -> {:error, :map_not_found}
    end
  end
end


defmodule Entice.Area.Sup do
  use Supervisor

  def start_link, do: Supervisor.start_link(__MODULE__, :ok)

  def init(:ok) do
    children = [
      supervisor(Entice.Area.HeroesAscent.Sup, []),
      supervisor(Entice.Area.RandomArenas.Sup, []),
      supervisor(Entice.Area.TeamArenas.Sup, [])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
