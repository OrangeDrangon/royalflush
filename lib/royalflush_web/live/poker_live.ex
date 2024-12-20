defmodule RoyalflushWeb.PokerLive do
  use RoyalflushWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>{@topic}</h1>
    <form phx-change="user-data-changed">
      <input type="text" name="name" value={@name} placeholder="Name" />
      <input type="text" name="vote" value={@vote} placeholder="Vote" />
    </form>
    <button phx-click="voted">
      <%= if @voted do %>
        hide vote
      <% else %>
        send vote
      <% end %>
    </button>

    <button phx-click="show_votes">
      <%= if @show_votes do %>
        clear votes
      <% else %>
        show votes
      <% end %>
    </button>

    <%= for {_, %{name: name, vote: vote, voted: voted}} <- @users do %>
      <div>
        <div>{name}</div>
        <div>
          <%= if voted do %>
            ✅
          <% else %>
            ❌
          <% end %>
        </div>
        <div>
          <%= if @show_votes && voted do %>
            {vote}
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  def mount(%{"id" => topic}, _session, socket) do
    name = "unknown"
    uuid = UUID.uuid4(:default)
    vote = ""
    voted = false

    if connected?(socket) do
      RoyalflushWeb.Endpoint.subscribe(topic)
      RoyalflushWeb.Endpoint.broadcast(topic, "new_user", nil)

      RoyalflushWeb.Endpoint.broadcast(topic, "update_user", %{
        uuid: uuid,
        payload: %{
          name: name,
          vote: vote,
          voted: voted
        }
      })
    end

    {:ok,
     socket
     |> assign(:topic, topic)
     |> assign(:name, name)
     |> assign(:uuid, uuid)
     |> assign(:vote, vote)
     |> assign(:voted, voted)
     |> assign(:show_votes, false)
     |> assign(:users, %{})}
  end

  def handle_event("user-data-changed", %{"name" => name, "vote" => vote}, socket) do
    RoyalflushWeb.Endpoint.broadcast(socket.assigns[:topic], "update_user", %{
      uuid: socket.assigns[:uuid],
      payload: %{
        name: name,
        vote: vote
      }
    })

    {:noreply, assign(socket, :name, name)}
  end

  def handle_event("voted", _params, socket) do
    voted = !socket.assigns[:voted]

    RoyalflushWeb.Endpoint.broadcast(socket.assigns[:topic], "update_user", %{
      uuid: socket.assigns[:uuid],
      payload: %{
        voted: voted
      }
    })

    {:noreply, assign(socket, :voted, voted)}
  end

  def handle_event("show_votes", _params, socket) do
    show_votes = !socket.assigns[:show_votes]

    RoyalflushWeb.Endpoint.broadcast(socket.assigns[:topic], "show_votes", show_votes)

    {:noreply, assign(socket, :show_votes, show_votes)}
  end

  def handle_info(
        %{event: "update_user", payload: %{uuid: uuid, payload: payload}},
        socket
      ) do
    {
      :noreply,
      assign(
        socket,
        :users,
        Map.update(socket.assigns[:users], uuid, payload, &Map.merge(&1, payload))
      )
    }
  end

  def handle_info(%{event: "new_user"}, socket) do
    RoyalflushWeb.Endpoint.broadcast(socket.assigns[:topic], "update_user", %{
      uuid: socket.assigns[:uuid],
      payload: %{
        name: socket.assigns[:name],
        vote: socket.assigns[:vote],
        voted: socket.assigns[:voted]
      }
    })

    {:noreply, socket}
  end

  def handle_info(%{event: "show_votes", payload: show_votes}, socket) do
    {:noreply, assign(socket, :show_votes, show_votes)}
  end
end
