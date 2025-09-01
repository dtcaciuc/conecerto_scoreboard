defmodule Conecerto.ScoreboardWeb.Layouts do
  use Conecerto.ScoreboardWeb, :html

  embed_templates "layouts/*"

  def header(assigns) do
    ~H"""
    <header class={[
      "print:hidden top-0 sticky z-50 mb3 flex justify-center border-b-2",
      "bg-[color:--header-fill-color] border-[--header-border-color]"
    ]}>
      <div class="flex justify-around basis-md">
        <div class={[
          "flex-auto flex max-sm:flex-col",
          if(@organizer != nil, do: "justify-between", else: "justify-around")
        ]}>
          <.organizer_logo conn={@conn} organizer={@organizer} />
          <div class="flex text-xl text-center justify-center leading-[3rem] child:block child:px-2 font-semibold">
            <%= for tab <- tabs(@conn) do %>
              <a class={tab_class(tab.title == @active_tab)} href={tab.path}>{tab.title}</a>
            <% end %>
          </div>
        </div>
      </div>
    </header>
    """
  end

  attr :conn, :map
  attr :organizer, :map

  def organizer_logo(%{organizer: nil} = assigns), do: ~H""

  def organizer_logo(assigns) do
    ~H"""
    <a href={@organizer.url} class="flex sm:h-[3rem] max-sm:h-[4rem] max-sm:justify-center">
      <img src={brand_path(@conn, @organizer)} class="object-contain object-center" />
    </a>
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
      "border-b-2 border-[--header-active-text-color]",
      "text-[--header-active-text-color] mb-[-2px]"
    ]

  defp tab_class(false = _active), do: ""

  attr :conn, :map
  attr :sponsors, :list
  attr :show_title, :boolean, default: true

  def sponsor_logos(%{sponsors: []} = assigns), do: ~H""

  def sponsor_logos(assigns) do
    ~H"""
    <div class="break-inside-avoid">
      <div :if={@show_title} class="text-xl text-center font-semibold pb-2">Sponsored By</div>
      <div class="flex flex-wrap justify-around bg-white p-2 gap-2">
        <%= for sponsor <- @sponsors do %>
          <a href={sponsor.url} target="_blank" class="flex">
            <img src={brand_path(@conn, sponsor)} class="h-[4rem] object-contain shrink-1" />
          </a>
        <% end %>
      </div>
    </div>
    """
  end

  def title_suffix(event_date, nil = _event_name),
    do: " · #{event_date} · Conecerto Scoreboard"

  def title_suffix(event_date, event_name),
    do: " · #{event_name} · #{event_date} · Conecerto Scoreboard"

  defp brand_path(conn, brand),
    do: with_base_path(conn, @endpoint.path(brand.path))
end
