Rails.application.routes.draw do
  mount PgBouncerHero::Engine, at: "/pgbouncerhero"
end
