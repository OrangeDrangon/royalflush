defmodule RoyalflushWeb.PageController do
  use RoyalflushWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
