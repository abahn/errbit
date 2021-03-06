class Problem < ActiveRecord::Base
  include Authority::Abilities
  include ProblemRepository
  include Distribution

  belongs_to :app, inverse_of: :problems
  has_many :comments, inverse_of: :problem, dependent: :delete_all
  has_many :notices, inverse_of: :problem, dependent: :delete_all

  counter_culture :app, column_name: ->(model){ "unresolved_problems_count" if model.unresolved? },
                        column_names: { ["problems.state = ?", 'unresolved'] => 'unresolved_problems_count' }

  distribution :message, :host, :user_agent

  validates_presence_of :environment, :fingerprint

  before_create :cache_app_attributes
  after_initialize :default_values

  validates_presence_of :last_notice_at, :first_notice_at

  state_machine initial: :unresolved do
    event :resolve do
      transition :unresolved => :resolved
    end

    event :unresolve do
      transition :resolved => :unresolved
    end

    before_transition any => :resolved do |problem|
      problem.resolved_at = Time.current
    end

    before_transition any => :unresolved do |problem|
      problem.resolved_at = nil
      problem.notices_count_before_unresolve = problem.notices_count
    end
  end

  def default_values
    if self.new_record?
      self.first_notice_at ||= Time.new
      self.last_notice_at ||= Time.new
    end
  end

  def comments_allowed?
    Errbit::Config.allow_comments_with_issue_tracker || !app.issue_tracker_configured?
  end

  def notices_count_since_unresolve
    notices_count - notices_count_before_unresolve
  end

  def cache_app_attributes
    if app
      self.last_deploy_at = if (last_deploy = app.deploys.where(:environment => self.environment).last)
        last_deploy.created_at.utc
      end
      Problem.where(id: self).update_all(
        last_deploy_at: self.last_deploy_at
      )
    end
  end

  def issue_type
    # Return issue_type if configured, but fall back to detecting app's issue tracker
    attributes['issue_type'] ||=
    (app.issue_tracker_configured? && app.issue_tracker.label) || nil
  end

  def inc(attr, increment_by)
    self.update_attribute(attr, self.send(attr) + increment_by)
  end
end

