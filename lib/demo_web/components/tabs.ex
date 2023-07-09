defmodule DemoWeb.Components.Tabs do
  @moduledoc """
  A tabs live component.
  """

  use Phoenix.LiveComponent
  alias Phoenix.LiveView.Socket

  defmodule Tab do
    @moduledoc """
    Struct representing a tab slot.
    """
    defstruct [:id, :label, :slot]

    alias __MODULE__

    @type t :: %Tab{
            id: atom(),
            label: String.t(),
            slot: map()
          }
  end

  defmodule State do
    @moduledoc """
    Struct representing the state of the tab component.
    The module also includes some functionality regarding the state.
    """
    defstruct [:id, :active_id, :tabs, :maybe_inner_state, :uri, :inform_parent?]

    alias __MODULE__

    @type t :: %State{
            id: atom(),
            active_id: atom(),
            tabs: list(Tab.t()),
            maybe_inner_state: any(),
            uri: URI.t(),
            inform_parent?: boolean()
          }

    @spec active_slot(State.t()) :: map()
    def active_slot(%State{tabs: tabs, active_id: active_id}) do
      %Tab{slot: slot} = Enum.find(tabs, fn tab -> tab.id == active_id end)
      slot
    end

    @spec active?(State.t(), atom()) :: boolean()
    def active?(%State{active_id: active_id}, tab) do
      active_id == tab.id
    end
  end

  @impl true
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

  @impl true
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

  @impl true
  def handle_event("change_tab", %{"id" => raw_id}, socket) do
    state = socket.assigns.state
    new_uri = put_param(state.uri, state.id |> Atom.to_string(), raw_id)

    if state.inform_parent? do
      send(self(), {:tab_changed, state.id, raw_id |> String.to_existing_atom()})
    end

    {:noreply, socket |> push_patch(to: URI.to_string(new_uri))}
  end

  @doc """
  Puts a new active tab, identified by its atom-id for a given
  tab component, identified by its atom-id. 
  Push patches the socket.
  """
  @spec put_active(Socket.t(), atom(), atom()) :: Socket.t()
  def put_active(socket, tab, id \\ :tabs) do
    state = Map.get(socket.assigns, id)
    uri = put_param(state.uri, id |> Atom.to_string(), tab |> Atom.to_string())
    push_patch(socket, to: URI.to_string(uri))
  end

  @doc """
  Initializes a tab component.
  It creates a new tab state and assigns it in the socket.
  It also registers a hook for parameter handling.

  Takes two optional parameters:

  - `:id` - the id of the tab component. Defaults to :tabs
  - `inform_parent?` - a flag determining if the component should inform the parent live view.
  """
  @spec init(Socket.t(), keyword()) :: Socket.t()
  def init(socket, opts \\ []) do
    id = Keyword.get(opts, :id, :tabs)
    id_str = Atom.to_string(id)

    inform_parent? = Keyword.get(opts, :inform_parent?, false)

    socket
    |> assign(id, %State{id: id, inform_parent?: inform_parent?})
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

  @spec make_tabs(list(map())) :: list(Tabs.t())
  defp make_tabs(slots),
    do: Enum.map(slots, fn slot -> %Tab{id: slot.id, label: slot.label, slot: slot} end)

  @spec put_param(URI.t(), String.t(), String.t()) :: URI.t()
  defp put_param(%URI{} = uri, key, value) do
    current_params = URI.decode_query(uri.query || "")
    new_params = Map.put(current_params, key, value)
    ((uri.path || "") <> "?" <> URI.encode_query(new_params)) |> URI.parse()
  end
end
