defmodule Conecerto.ScoreboardWeb.ScoresHTML do
  use Conecerto.ScoreboardWeb, :html

  embed_templates "scores_html/*"

  def sponsor_logos(%{sponsors: []} = assigns), do: ~H""

  def sponsor_logos(assigns) do
    ~H"""
    <div class="mt-4">
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
