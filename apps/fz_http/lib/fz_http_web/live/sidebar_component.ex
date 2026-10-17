defmodule FzHttpWeb.SidebarComponent do
  @moduledoc """
  Admin Sidebar
  """
  use FzHttpWeb, :live_component

  def render(assigns) do
    ~H"""
    <aside class="aside is-placed-left is-expanded is-vertically-scrollable ">
      <div class="aside-tools">
        <div class="aside-tools-label">
          <span>Firezone</span>
        </div>
      </div>
      <div class="menu is-menu-main">
        <p class="menu-label">Configuration</p>
        <ul class="menu-list">
          <li>
            <.link navigate={~p"/users"} class={nav_class(@path, "/users")}>
              <span class="icon"><i class="mdi mdi-account-group"></i></span>
              <span class="menu-item-label">Users</span>
            </.link>
          </li>
          <li>
            <.link navigate={~p"/devices"} class={nav_class(@path, "/devices")}>
              <span class="icon"><i class="mdi mdi-laptop"></i></span>
              <span class="menu-item-label">Devices</span>
            </.link>
          </li>
          <li>
            <.link navigate={~p"/rules"} class={nav_class(@path, "/rules")}>
              <span class="icon"><i class="mdi mdi-traffic-light"></i></span>
              <span class="menu-item-label">Rules</span>
            </.link>
          </li>
        </ul>
        <p class="menu-label">Settings</p>
        <ul class="menu-list">
          <li>
            <.link
              navigate={~p"/settings/client_defaults"}
              class={nav_class(@path, "/settings/client_defaults")}
            >
              <span class="icon"><i class="mdi mdi-cog"></i></span>
              <span class="menu-item-label">Defaults</span>
            </.link>
          </li>
          <li>
            <.link navigate={~p"/settings/account"} class={nav_class(@path, "/settings/account")}>
              <span class="icon"><i class="mdi mdi-account"></i></span>
              <span class="menu-item-label">Account</span>
            </.link>
          </li>
          <li>
            <.link
              navigate={~p"/settings/customization"}
              class={nav_class(@path, "/settings/customization")}
            >
              <span class="icon"><i class="mdi mdi-palette"></i></span>
              <span class="menu-item-label">Customization</span>
            </.link>
          </li>
          <li>
            <.link navigate={~p"/settings/security"} class={nav_class(@path, "/settings/security")}>
              <span class="icon"><i class="mdi mdi-lock"></i></span>
              <span class="menu-item-label">Security</span>
            </.link>
          </li>
        </ul>
        <p class="menu-label">Diagnostics</p>
        <ul class="menu-list">
          <li>
            <.link
              navigate={~p"/diagnostics/connectivity_checks"}
              class={nav_class(@path, "/diagnostics/connectivity_checks")}
            >
              <span class="icon"><i class="mdi mdi-access-point"></i></span>
              <span class="menu-item-label">WAN Connectivity</span>
            </.link>
          </li>
        </ul>
      </div>
    </aside>
    """
  end

  def nav_class(path, prefix) do
    if String.starts_with?(path, prefix) do
      "is-active has-icon"
    else
      "has-icon"
    end
  end
end
