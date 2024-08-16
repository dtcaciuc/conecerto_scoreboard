defmodule Conecerto.ScoreboardWeb.Layouts do
  use Conecerto.ScoreboardWeb, :html

  embed_templates "layouts/*"

  def top_nav(assigns) do
    ~H"""
    <div class="top-0 sticky z-50 mb3 bg-neutral-800 text-white text-2xl flex justify-center border-b-2 border-neutral-700">
      <div class="flex justify-between basis-md">
        <div class="flex-auto flex max-sm:flex-col">
          <.organizer_logo organizer={Conecerto.ScoreboardWeb.Brands.get_organizer()} />
          <div class="flex flex-auto text-center child:grow child:block child:p-2">
            <%= for tab <- tabs() do %>
              <a class={tab_class(tab.title == @active_tab)} href={tab.url}><%= tab.title %></a>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp organizer_logo(%{organizer: nil} = assigns), do: ~H""

  defp organizer_logo(assigns) do
    ~H"""
    <div class="flex flex-auto max-sm:justify-center">
      <img src={@organizer.url} class="object-contain object-left sm:h-[3rem] max-sm:h-[4.0rem]" />
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

  defp tab_class(true = _active), do: "border-b-2 border-red-500 text-red-500 mb-[-2px]"
  defp tab_class(false = _active), do: ""

  def sponsor_logos(%{sponsors: []} = assigns), do: ~H""

  def sponsor_logos(assigns) do
    ~H"""
    <div class="bg-neutral-900 text-white mt-4">
      <div class="text-xl text-center font-semibold pb-2">Sponsored By</div>
      <div class="flex flex-wrap justify-around bg-white my-2 p-2 gap-2">
        <%= for sponsor <- @sponsors do %>
          <img src={sponsor.url} class="h-[4rem] object-contain shrink-1" />
        <% end %>
      </div>
    </div>
    """
  end
end
