defmodule FzHttp.CaseTemplate do
  @moduledoc """
  Our wrapper for the ExUnit.CaseTemplate to provide metaprogrammed
  helpers to all tests.
  """

  defmacro __using__(_opts) do
    quote do
      use ExUnit.CaseTemplate
      alias Ecto.Adapters.SQL.Sandbox

      setup tags do
        :ok = Sandbox.checkout(FzHttp.Repo)

        unless tags[:async] do
          Sandbox.mode(FzHttp.Repo, {:shared, self()})
        end

        :ok
      end
    end
  end
end
