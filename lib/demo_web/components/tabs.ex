defmodule DemoWeb.Components.Tabs do
  @moduledoc """
  A tabs live component.
  """

  use Phoenix.LiveComponent

  defmodule Tab do
    defstruct [:id, :label, :slot]
  end

  defmodule State do
    defstruct [:active_id, :tabs, :maybe_inner_state, :uri]

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
    maybe_inner_state = Map.get(assigns, :state)

    tabs = make_tabs(assigns.tab)

    state = assigns.tabs
    active_id = assigns.tabs.active_id || hd(tabs).id

    updated_state = %State{
      state
      | maybe_inner_state: maybe_inner_state,
        tabs: tabs,
        active_id: active_id
    }

    {:ok, socket |> assign(:state, updated_state)}
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
    uri = socket.assigns.state.uri
    new_uri = put_param(uri, "tabs", raw_id)
    {:noreply, socket |> push_patch(to: URI.to_string(new_uri))}
  end

  def init(socket) do
    socket
    |> assign(:tabs, %State{})
    |> attach_hook(:tabs_hook, :handle_params, fn params, uri, socket ->
      state = socket.assigns.tabs
      parsed_uri = URI.parse(uri)

      if Map.has_key?(params, "tabs") do
        tabs = Map.get(params, "tabs") |> String.to_existing_atom()
        next_state = %State{state | uri: parsed_uri, active_id: tabs}
        {:cont, socket |> assign(:tabs, next_state)}
      else
        next_state = %State{state | uri: parsed_uri}
        {:cont, socket |> assign(:tabs, next_state)}
      end
    end)
  end

  defp initialized?(socket), do: Map.has_key?(socket.assigns, :state)

  defp make_tabs(slots),
    do: Enum.map(slots, fn slot -> %Tab{id: slot.id, label: slot.label, slot: slot} end)

  defp put_param(%URI{} = uri, key, value) do
    current_params = URI.decode_query(uri.query || "")
    new_params = Map.put(current_params, key, value)
    ((uri.path || "") <> "?" <> URI.encode_query(new_params)) |> URI.parse()
  end
end
