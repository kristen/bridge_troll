class EventSession < ActiveRecord::Base
  attr_accessible :starts_at, :ends_at, :name, :required_for_students
  validates_presence_of :starts_at, :ends_at, :name
  validates_uniqueness_of :name, scope: [:event_id]

  belongs_to :event, inverse_of: :event_sessions
  has_many :rsvp_sessions, dependent: :destroy
  has_many :rsvps, :through => :rsvp_sessions

  after_save :update_event_times
  after_destroy :update_event_times

  def update_event_times
    return unless event

    # TODO: This 'reload' shouldn't be needed, but without it, the
    # following minimum/maximum statements return 'nil' when
    # initially creating an event and its session. Booo!
    event.reload
    event.update_attributes(
      starts_at: event.event_sessions.minimum("event_sessions.starts_at"),
      ends_at: event.event_sessions.maximum("event_sessions.ends_at")
    )
  end

  def starts_at
    (event && event.persisted?) ? date_in_time_zone(:starts_at) : read_attribute(:starts_at)
  end

  def ends_at
    (event && event.persisted?) ? date_in_time_zone(:ends_at) : read_attribute(:ends_at)
  end

  def session_date
    (starts_at ? starts_at : Date.current).strftime('%Y-%m-%d')
  end

  def date_in_time_zone start_or_end
    read_attribute(start_or_end).in_time_zone(ActiveSupport::TimeZone.new(event.time_zone))
  end
end
