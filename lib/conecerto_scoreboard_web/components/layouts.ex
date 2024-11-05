defmodule Conecerto.ScoreboardWeb.Layouts do
  use Conecerto.ScoreboardWeb, :html

  embed_templates "layouts/*"

  def top_nav(assigns) do
    ~H"""
    <div class={[
      "top-0 sticky z-50 mb3 flex justify-center border-b-2",
      "bg-[color:--top-nav-fill-color] border-[--top-nav-border-color]"
    ]}>
      <div class="flex justify-between basis-md">
        <div class="flex-auto flex max-sm:flex-col">
          <.organizer_logo conn={@conn} organizer={@organizer} />
          <div class="flex text-xl text-center justify-center leading-[3rem] child:block child:px-2 font-semibold">
            <%= for tab <- tabs(@conn) do %>
              <a class={tab_class(tab.title == @active_tab)} href={tab.path}><%= tab.title %></a>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :conn, :map
  attr :organizer, :map

  defp organizer_logo(%{organizer: nil} = assigns), do: ~H""

  defp organizer_logo(assigns) do
    ~H"""
    <div class="flex flex-auto max-sm:justify-center basis-full sm:h-[3rem] max-sm:h-[4rem]">
      <img src={brand_path(@conn, @organizer)} class="object-contain object-left" />
    </div>
    """
  end

  defp tabs(conn) do
    [
      %{title: "Event", path: ~p"/event"},
      %{title: "Raw", path: ~p"/raw"},
      %{title: "PAX", path: ~p"/pax"},
      %{title: "Groups", path: ~p"/groups"},
      %{title: "Runs", path: ~p"/runs"},
      %{title: "Δs", path: ~p"/cones"}
    ]
    |> Enum.map(fn %{path: path} = tab ->
      %{tab | path: with_base_path(conn, path)}
    end)
  end

  defp tab_class(true = _active),
    do: [
      "border-b-2 border-[--top-nav-active-text-color]",
      "text-[--top-nav-active-text-color] mb-[-2px]"
    ]

  defp tab_class(false = _active), do: ""

  attr :conn, :map
  attr :sponsors, :list

  def sponsor_logos(%{sponsors: []} = assigns), do: ~H""

  def sponsor_logos(assigns) do
    ~H"""
    <div class="mt-4">
      <div class="text-xl text-center font-semibold pb-2">Sponsored By</div>
      <div class="flex flex-wrap justify-around bg-white my-2 p-2 gap-2">
        <%= for sponsor <- @sponsors do %>
          <img src={brand_path(@conn, sponsor)} class="h-[4rem] object-contain shrink-1" />
        <% end %>
      </div>
    </div>
    """
  end

  defp brand_path(conn, brand),
    do: with_base_path(conn, @endpoint.path(brand.path))
end
