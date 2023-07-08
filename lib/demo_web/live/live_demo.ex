defmodule DemoWeb.LiveDemo do
  use DemoWeb, :live_view

  alias DemoWeb.Components.Tabs

  def mount(_params, _session, socket) do
    next_socket = socket |> assign(:counter, 0)
    {:ok, next_socket}
  end

  def render(assigns) do
    ~H"""
    <.live_component module={Tabs} id="tabs" state={@counter}>
      <:tab :let={state} label="Tab 1" id={:name_tab}><%= state %></:tab>
      <:tab label="Tab 2" id={:address_tab}>Tab 2</:tab>
    </.live_component>

    <p phx-click="increment">Increment</p>
    <p><%= @counter %></p>
    """
  end

  def handle_event("increment", _, socket) do
    next_socket = socket |> update(:counter, fn counter -> counter + 1 end)
    {:noreply, next_socket}
  end
end
