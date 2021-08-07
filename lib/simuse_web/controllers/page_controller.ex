defmodule SimuseWeb.PageController do
  use SimuseWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
