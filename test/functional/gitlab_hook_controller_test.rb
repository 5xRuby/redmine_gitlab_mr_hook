# frozen_string_literal: true

require_relative '../../../../test/test_helper'

class GitlabHookControllerTest < Redmine::ControllerTest
  fixtures :projects, :enabled_modules, :repositories, :users

  MERGED = {object_kind: 'merge_request', object_attributes: {action: 'merge'}}.freeze

  def setup
    ENV['GITLAB_HOOK_SECRET'] = 's3cret'
    @repo = Repository::Git.create!(project_id: 1, url: '/tmp/none.git', identifier: 'hook')
  end

  def teardown
    ENV.delete('GITLAB_HOOK_SECRET')
  end

  def test_wrong_token_is_unauthorized
    @request.headers['X-Gitlab-Token'] = 'nope'
    post :create, params: MERGED.merge(project: @repo.project.identifier)
    assert_response :unauthorized
  end

  def test_non_merge_event_is_ignored
    @request.headers['X-Gitlab-Token'] = 's3cret'
    Repository::Git.any_instance.expects(:fetch_changesets).never
    post :create, params: {object_kind: 'merge_request', object_attributes: {action: 'open'}, project: @repo.project.identifier}
    assert_response :ok
  end

  def test_merge_event_fetches_and_scans
    @request.headers['X-Gitlab-Token'] = 's3cret'
    Open3.expects(:capture2e).returns(['', stub(success?: true)])
    Repository::Git.any_instance.expects(:fetch_changesets)
    post :create, params: MERGED.merge(project: @repo.project.identifier, repository: @repo.identifier)
    assert_response :ok
  end
end
