# frozen_string_literal: true

Redmine::Plugin.register :redmine_gitlab_mr_hook do
  name 'GitLab MR Hook'
  author '5xRuby CO., LTD'
  description 'Fetch the local git clone and run Redmine built-in changeset scanning when a GitLab MR is merged'
  version '0.1.0'
end
