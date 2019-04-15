defmodule CourtbotWeb.HealthController do
  @moduledoc false
  use CourtbotWeb, :controller

  def health(conn, _params), do: send_resp(conn, :ok, "")
end
