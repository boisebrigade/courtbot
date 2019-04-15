defmodule CourtbotWeb do
  @moduledoc false

  def controller do
    quote do
      use Phoenix.Controller, namespace: CourtbotWeb
      import Plug.Conn
      import CourtbotWeb.Router.Helpers
      import CourtbotWeb.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/courtbot_web/templates",
        namespace: CourtbotWeb

      # Import convenience functions from controllers
      import CourtbotWeb.Router.Helpers
      import CourtbotWeb.ErrorHelpers
      import CourtbotWeb.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
