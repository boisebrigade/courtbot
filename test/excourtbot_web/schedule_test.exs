defmodule ExCourtbotWeb.ScheduleTest do
  use ExCourtbotWeb.ConnCase, async: true

  defmodule TestTimeScale do
    def now(_) do
      DateTime.utc_now()
    end

    def speedup do
      86400 # skip one day
    end
  end

  test "import runs at 0900 everyday" do
    # IO.inspect SchedEx.run_every(&ExCourtbot.import/0, "0 10 * * *", time_scale: TestTimeScale)

    # Process.sleep(1000)
  end

  test "notifications runs at 1300 everday" do
    # IO.inspect SchedEx.run_every(&ExCourtbot.notify/0,  "0 13 * * *", time_scale: TestTimeScale)

    # Process.sleep(1000)
  end

end
