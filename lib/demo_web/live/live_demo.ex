defmodule DemoWeb.LiveDemo do
  use DemoWeb, :live_view

  alias DemoWeb.Components.Tabs

  def mount(_params, _session, socket) do
    next_socket = socket |> Tabs.init(id: :tabs_1) |> Tabs.init(id: :tabs_2)
    {:ok, next_socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col space-y-10">
      <.live_component module={Tabs} id="tabs_1" tabs={@tabs_1}>
        <:tab label="Tab 1" id={:name_tab}>Tab 1</:tab>
        <:tab label="Tab 2" id={:address_tab}>Tab 2</:tab>
      </.live_component>
      <.live_component module={Tabs} id="tabs_2" tabs={@tabs_2}>
        <:tab label="Tab 1" id={:name_tab}>Tab 1</:tab>
        <:tab label="Tab 2" id={:address_tab}>Tab 2</:tab>
      </.live_component>
    </div>
    """
  end

  def handle_params(_url, _params, socket) do
    {:noreply, socket}
  end
end
