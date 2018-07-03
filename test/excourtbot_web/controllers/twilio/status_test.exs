defmodule ExCourtbotWeb.TwilioStatusTest do
  use ExCourtbotWeb.ConnCase, async: true

  test "you can reach the status endpoint", %{conn: conn} do
    conn = get conn, "/status"
    assert conn.status == 200
  end
end
