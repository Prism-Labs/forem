module Autoposts
  class Creator
    def initialize(user, autopost_params, event_dispatcher = Webhook::DispatchEvent)
      @user = user
      @autopost_params = autopost_params
      @event_dispatcher = event_dispatcher
    end

    def self.call(...)
      new(...).call
    end

    def call
      rate_limit!

      autopost = save_autopost

      if autopost.persisted?
        # # Subscribe author to notifications for all comments on their autopost.
        # NotificationSubscription.create(user: user, notifiable_id: autopost.id, notifiable_type: "Autopost",
        #                                 config: "all_comments")

        # # Send notifications to any mentioned users, followed by any users who follow the autopost's author.
        # Notification.send_to_mentioned_users_and_followers(autopost) if autopost.published?
        # dispatch_event(autopost)
      end

      autopost
    end

    private

    attr_reader :user, :autopost_params, :event_dispatcher

    def rate_limit!
      rate_limit_to_use = if user.decorate.considered_new?
                            :published_autopost_antispam_creation
                          else
                            :published_autopost_creation
                          end

      user.rate_limiter.check_limit!(rate_limit_to_use)
    end

    def dispatch_event(autopost)
      return unless autopost.published?

      event_dispatcher.call("autopost_created", autopost)
    end

    def save_autopost
      series = autopost_params[:series]
      tags = autopost_params[:tags]

      # convert tags from array to a string
      if tags.present?
        autopost_params.delete(:tags)
        autopost_params[:tag_list] = tags.join(", ")
      end

      autopost = Autopost.new(autopost_params)
      autopost.user_id = user.id
      autopost.collection = Collection.find_series(series, user) if series.present?
      autopost.save
      autopost
    end
  end
end
