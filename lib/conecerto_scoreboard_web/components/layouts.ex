defmodule Conecerto.ScoreboardWeb.Layouts do
  use Conecerto.ScoreboardWeb, :html

  embed_templates "layouts/*"

  def top_nav(assigns) do
    ~H"""
    <div class="top-0 sticky z-50 flex mb3 bg-neutral-800 text-white text-2xl">
      <div class={tab_class(false)} />
      <div class="flex justify-between basis-md">
        <%= for tab <- tabs() do %>
          <% active = tab.title == @active_tab %>
          <div class={tab_class(active)}>
            <a class={tab_text_class(active)} href={tab.url}><%= tab.title %></a>
          </div>
        <% end %>
      </div>
      <div class={tab_class(false)} />
    </div>
    """
  end

  defp tabs() do
    [
      %{title: "Event", url: ~p"/"},
      %{title: "Raw", url: ~p"/raw"},
      %{title: "PAX", url: ~p"/pax"},
      %{title: "Groups", url: ~p"/groups"},
      %{title: "Runs", url: ~p"/runs"}
    ]
  end

  defp tab_class(true = _active), do: "flex-auto text-center border-b-2 py-2 border-red-500"
  defp tab_class(false = _active), do: "flex-auto text-center border-b-2 py-2 border-neutral-700"

  defp tab_text_class(true = _active), do: "text-red-500"
  defp tab_text_class(false = _active), do: "white"
end
