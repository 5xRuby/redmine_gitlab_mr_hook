# frozen_string_literal: true

require 'open3'

# POST /gitlab_hook?project=<identifier>[&repository=<repo identifier>]
# GitLab webhook (Merge request events). Secret token: ENV['GITLAB_HOOK_SECRET'].
class GitlabHookController < ApplicationController
  skip_before_action :check_if_login_required, :verify_authenticity_token

  def create
    secret = ENV['GITLAB_HOOK_SECRET'].to_s
    token = request.headers['X-Gitlab-Token'].to_s
    return head :unauthorized if secret.empty? || !ActiveSupport::SecurityUtils.secure_compare(token, secret)
    return head :ok unless params[:object_kind] == 'merge_request' && params.dig(:object_attributes, :action) == 'merge'

    project = Project.active.has_module(:repository).find_by_param(params[:project].to_s)
    repository = project&.repositories&.detect {|r| r.is_a?(Repository::Git) && (params[:repository].blank? || r.identifier == params[:repository])}
    return head :not_found unless repository

    # Redmine never runs `git fetch` itself; update the bare clone first.
    _, status = Open3.capture2e('git', '--git-dir', repository.url, 'fetch', 'origin', '+refs/heads/*:refs/heads/*')
    return head :bad_gateway unless status.success?

    repository.fetch_changesets # built-in: keyword scan, fix_issue, time logging
    head :ok
  end
end
