defmodule DemoWeb.LiveDemo do
  use DemoWeb, :live_view

  alias DemoWeb.Components.Tabs

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.live_component module={Tabs} id="tabs">
      <:tab label="Tab 1" id={:name_tab}>Tab 1</:tab>
      <:tab label="Tab 2" id={:address_tab}>Tab 2</:tab>
    </.live_component>
    """
  end
end
