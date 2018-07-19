defmodule ExCourtbotWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext),
  your module gains a set of macros for translations, for example:

      import ExCourtbotWeb.Gettext

      # Simple translation
      gettext "Here is the string to translate"

      # Plural translation
      ngettext "Here is the string to translate",
               "Here are the strings to translate",
               3

      # Domain-based translation
      dgettext "errors", "Here is the error message to translate"

  See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.
  """
  use Gettext, otp_app: :excourtbot

  defp locale(to_number, message) do
    locales =
      Application.get_env(:excourtbot, ExCourtbot)
      |> Keyword.fetch(:locales)

    #    locale = Enum.map(locales, fn {lo, number}
    #
    #    end)

    case locales do
      test ->
        Gettext.with_locale(test, fn ->
          gettext(message)
        end)

      _ ->
        gettext(message)
    end
  end
end
