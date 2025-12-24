defmodule UrbanWayWeb.Router do
  use UrbanWayWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", UrbanWayWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", UrbanWayWeb do
    pipe_through :api

    resources "/locations", LocationController, only: [:index, :show, :create, :update, :delete]
    resources "/stops", StopController, only: [:index, :show, :create, :update, :delete]
    resources "/routes", RouteController, only: [:index, :show, :create, :update, :delete]
    get "/routes/:name/stops", RouteController, :stops

    get "/graph", GraphController, :index
    get "/pathfinder", PathfinderController, :find

    get "/relationships/next", RelationshipController, :index_next
    post "/relationships/next", RelationshipController, :create_next
    delete "/relationships/next", RelationshipController, :delete_next

    get "/relationships/transfers", RelationshipController, :index_transfers
    post "/relationships/transfers", RelationshipController, :create_transfer
    delete "/relationships/transfers", RelationshipController, :delete_transfer

    get "/relationships/nearby", RelationshipController, :index_nearby
    post "/relationships/nearby", RelationshipController, :create_nearby
    delete "/relationships/nearby", RelationshipController, :delete_nearby
  end
end
