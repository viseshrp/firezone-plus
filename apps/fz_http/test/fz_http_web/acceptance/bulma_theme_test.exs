defmodule FzHttpWeb.Acceptance.BulmaThemeTest do
  use FzHttpWeb.AcceptanceCase, async: false
  alias FzHttp.UsersFixtures

  setup %{session: session} do
    user = UsersFixtures.create_user_with_role(:admin)
    %{session: session |> visit(~p"/") |> Auth.authenticate(user)}
  end

  feature "rule cards fit both desktop and mobile viewports", %{session: session} do
    session
    |> visit(~p"/rules")
    |> assert_has(Query.css(".grid > .cell", count: 2))
    |> execute_script(
      "const cells = [...document.querySelectorAll('.grid > .cell')]; return cells.map(c => c.getBoundingClientRect().top);",
      fn [first, second] -> assert abs(first - second) < 2 end
    )
    |> resize_window(390, 844)
    |> execute_script_async(
      """
      const done = arguments[arguments.length - 1];
      let frames = 0;
      function settled() {
        const aside = document.querySelector('aside.aside');
        if (!aside || aside.getBoundingClientRect().right <= 1) return done(true);
        if (++frames > 60) return done(false);
        requestAnimationFrame(settled);
      }
      settled();
      """,
      fn settled -> assert settled, "mobile navigation must finish sliding off the content" end
    )
    |> execute_script(
      """
      const cells = [...document.querySelectorAll('.grid > .cell')];
      return {
        tops: cells.map(c => c.getBoundingClientRect().top),
        width: document.documentElement.scrollWidth,
        viewport: innerWidth
      };
      """,
      fn result ->
        assert Enum.at(result["tops"], 1) > Enum.at(result["tops"], 0)
        assert result["width"] <= result["viewport"] + 1
      end
    )
    |> Wallaby.Browser.take_screenshot(name: "bulma-1-mobile-rules")
  end

  feature "security switches retain their native keyboard interaction", %{session: session} do
    selector = "input[name=allow_unprivileged_device_management]"

    session
    |> visit(~p"/settings/security")
    |> assert_has(Query.css(selector <> ":checked", visible: :any))
    |> execute_script(
      "const el = document.querySelector(arguments[0]); el.focus(); return document.activeElement === el;",
      [selector],
      fn focused -> assert focused end
    )
    |> send_keys([:space])
    |> assert_has(Query.css(selector <> ":not(:checked)", visible: :any))
    |> send_keys([:space])
    |> assert_has(Query.css(selector <> ":checked", visible: :any))
    |> Wallaby.Browser.take_screenshot(name: "bulma-1-security-switches")
  end
end
