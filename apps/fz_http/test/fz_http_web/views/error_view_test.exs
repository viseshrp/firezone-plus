defmodule FzHttpWeb.ErrorViewTest do
  use FzHttpWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(FzHttpWeb.ErrorView, "404.html", []) == "Not Found"
  end

  test "renders 500.html" do
    assert render_to_string(FzHttpWeb.ErrorView, "500.html", []) == "Internal Server Error"
  end

  test "renders exception reasons without leaking internal details" do
    assigns = [reason: RuntimeError.exception("private database detail")]

    assert render_to_string(FzHttpWeb.ErrorView, "500.html", assigns) == "Internal Server Error"

    assert FzHttpWeb.ErrorView.render("500.json", assigns) == %{
             "error" => "Internal Server Error"
           }
  end
end
