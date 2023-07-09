defmodule DemoWeb.Components.Tabs do
  @moduledoc """
  A tabs live component.
  """

  use Phoenix.LiveComponent

  defmodule Tab do
    defstruct [:id, :label, :slot]
  end

  defmodule State do
    defstruct [:id, :active_id, :tabs, :maybe_inner_state, :uri]

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
    state = socket.assigns.state
    new_uri = put_param(state.uri, state.id |> Atom.to_string(), raw_id)
    {:noreply, socket |> push_patch(to: URI.to_string(new_uri))}
  end

  def init(socket, opts \\ []) do
    id = Keyword.get(opts, :id, :tabs)
    id_str = Atom.to_string(id)

    socket
    |> assign(id, %State{id: id})
    |> attach_hook(:"#{id}_hook", :handle_params, fn params, uri, socket ->
      state = Map.get(socket.assigns, id)
      parsed_uri = URI.parse(uri)

      tab =
        if Map.has_key?(params, id_str) do
          Map.get(params, id_str) |> String.to_existing_atom()
        end

      next_state = %State{state | uri: parsed_uri, active_id: tab}
      {:cont, socket |> assign(id, next_state)}
    end)
  end

  defp make_tabs(slots),
    do: Enum.map(slots, fn slot -> %Tab{id: slot.id, label: slot.label, slot: slot} end)

  defp put_param(%URI{} = uri, key, value) do
    current_params = URI.decode_query(uri.query || "")
    new_params = Map.put(current_params, key, value)
    ((uri.path || "") <> "?" <> URI.encode_query(new_params)) |> URI.parse()
  end
end
