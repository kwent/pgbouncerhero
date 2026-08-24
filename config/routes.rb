PgBouncerHero::Engine.routes.draw do
  group_exists = ->(request) { PgBouncerHero.groups.key?(request.params[:group]) }
  database_exists = lambda do |request|
    group = PgBouncerHero.groups[request.params[:group]]
    group&.databases&.any? { |database| database.name.parameterize == request.params[:database] }
  end

  root to: "home#index"
  scope path: ":group", constraints: group_exists do
    scope path: ":database", constraints: database_exists do
      get :summary, controller: :database
      get :databases, controller: :database
      get :stats, controller: :database
      get :pools, controller: :database
      get :clients, controller: :database
      get :conf, controller: :database
      post :reload, controller: :database
      post :suspend, controller: :database
      post :shutdown, controller: :database
    end
  end
end
