require File.expand_path('../../test_helper', __FILE__)

class TimeLoggersControllerTest < Redmine::ControllerTest
  fixtures :time_loggers

  def setup
    @request.session[:user_id] = 2
  end

  def test_time_logger_start
    TimeLogger.delete_all

    get :start, :params => {:issue_id => 1}, :xhr => true
    assert_response :success
    assert_equal 'text/javascript', response.media_type

    # cannot start more than one time logger at the same time
    get :start, :params => {:issue_id => 2}, :xhr => true
    assert_response :bad_request
  end

  def test_time_logger_suspend
    get :suspend, :params => {:id => 1}, :xhr => true
    assert_response :success
    assert_equal 'text/javascript', response.media_type

    # should be replaced with resume button
    assert_match 'time-logger-resume-btn', response.body

    # can't be paused coz it's already paused
    get :suspend, :params => {:id => 1}, :xhr => true
    assert_response :bad_request
  end

  def test_time_logger_resume
    get :resume, :params => {:id => 2}, :xhr => true
    assert_response :success
    assert_equal 'text/javascript', response.media_type

    # should be replaced with suspend button
    assert_match 'time-logger-suspend-btn', response.body

    get :resume, :params => {:id => 2}, :xhr => true
    assert_response :bad_request
  end

  def test_time_logger_stop
    get :stop, :params => {:id => 1}
    # redirect to time_log or issue controller
    assert_response :found
    assert_nil TimeLogger.find_by(:id => 1)

    # nothing to stop
    get :stop, :params => {:id => 1, :back_url => home_url}
    # time logger not found
    # error shows and redirects back
    assert_redirected_to home_url
  end

  def test_time_logger_setting_redirect_to_new_time_entry
    tl = TimeLogger.find(1)

    Setting.plugin_time_logger['redirect_to_new_time_entry'] = true
    get :stop, :params => {:id => 1}
    assert_redirected_to :controller => 'timelog',
                         :action => 'new',
                         :issue_id => tl.issue_id,
                         :time_entry => { hours: tl.hours_spent }

    t = TimeLogger.create!(:issue_id => 1, :user_id => 2, :started_on => Time.now)
    Setting.plugin_time_logger['redirect_to_new_time_entry'] = nil
    get :stop, :params => {:id => t.id}
    assert_redirected_to controller: 'issues',
                         action: 'edit',
                         id: t.issue_id,
                         time_entry: { hours: t.hours_spent }
  end
end
