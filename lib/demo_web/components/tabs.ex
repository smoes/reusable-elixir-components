defmodule DemoWeb.Components.Tabs do
  @moduledoc """
  A tabs live component.
  """

  use Phoenix.LiveComponent

  defmodule Tab do
    defstruct [:id, :label, :slot]
  end

  defmodule State do
    defstruct [:active_id, :tabs, :maybe_inner_state]

    alias __MODULE__

    def active_slot(%State{tabs: tabs, active_id: active_id}) do
      %Tab{slot: slot} = Enum.find(tabs, fn tab -> tab.id == active_id end)
      slot
    end

    def active?(%State{active_id: active_id}, tab) do
      active_id == tab.id
    end
  end

  def update(assigns, socket) do
    maybe_state = Map.get(assigns, :state)

    unless initialized?(socket) do
      tabs = make_tabs(assigns.tab)
      active = hd(tabs).id
      state = %State{active_id: active, tabs: tabs, maybe_inner_state: maybe_state}
      {:ok, socket |> assign(:state, state)}
    else
      state = socket.assigns.state
      updated_state = %State{state | maybe_inner_state: maybe_state}
      {:ok, socket |> assign(:state, updated_state)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col space-y-5">
      <div class="flex flex-row space-x-3">
        <%= for tab <- @state.tabs do %>
          <div
            class={[
              "rounded-full p-3 pl-5 pr-5",
              if State.active?(@state, tab) do
                ["bg-white text-black"]
              else
                ["bg-black text-white"]
              end
            ]}
            phx-click="change_tab"
            phx-value-id={tab.id}
            phx-target={@myself}
          >
            <%= tab.label %>
          </div>
        <% end %>
      </div>
      <div>
        <%= render_slot(@state |> State.active_slot(), @state.maybe_inner_state) %>
      </div>
    </div>
    """
  end

  def handle_event("change_tab", %{"id" => raw_id}, socket) do
    id = String.to_existing_atom(raw_id)
    current_state = socket.assigns.state
    next_state = %State{current_state | active_id: id}
    {:noreply, socket |> assign(:state, next_state)}
  end

  defp initialized?(socket), do: Map.has_key?(socket.assigns, :state)

  defp make_tabs(slots),
    do: Enum.map(slots, fn slot -> %Tab{id: slot.id, label: slot.label, slot: slot} end)
end
