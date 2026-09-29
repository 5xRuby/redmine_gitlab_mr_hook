# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  post 'gitlab_hook', to: 'gitlab_hook#create'
end
