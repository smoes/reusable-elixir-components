defmodule DemoWeb.LiveDemo do
  use DemoWeb, :live_view

  alias DemoWeb.Components.Tabs

  def mount(_params, _session, socket) do
    {:ok, socket |> Tabs.init() |> assign(:counter, 0)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex space-y-10 flex-col">
      <.live_component module={Tabs} id="tabs" tabs={@tabs}>
        <:tab label="Tab 1" id={:name_tab}>Tab 1</:tab>
        <:tab label="Tab 2" id={:address_tab}>Tab 2</:tab>
      </.live_component>
      <.live_component module={Tabs} id="tabs 2" tabs={@tabs}>
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
