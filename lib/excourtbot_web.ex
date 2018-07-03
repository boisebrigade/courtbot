defmodule ExCourtbotWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use ExCourtbotWeb, :controller
      use ExCourtbotWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: ExCourtbotWeb
      import Plug.Conn
      import ExCourtbotWeb.Router.Helpers
      import ExCourtbotWeb.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/excourtbot_web/templates",
                        namespace: ExCourtbotWeb

      # Import convenience functions from controllers
      import ExCourtbotWeb.Router.Helpers
      import ExCourtbotWeb.ErrorHelpers
      import ExCourtbotWeb.Gettext
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
