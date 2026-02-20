PgBouncerHero::Engine.routes.draw do
  root to: "home#index"
  scope path: ":group", constraints: proc { |req| (PgBouncerHero.groups.keys.map(&:parameterize) + [ nil ]).include?(req.params[:group]) } do
    scope path: ":database", constraints: proc { |req| (PgBouncerHero.groups[req.params[:group]].databases.map(&:name).map(&:parameterize) + [ nil ]).include?(req.params[:database]) } do
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
