module Autoposts
  class Updater
    Result = Struct.new(:success, :autopost, keyword_init: true)

    def initialize(user, autopost, autopost_params, event_dispatcher = Webhook::DispatchEvent)
      @user = user
      @autopost = autopost
      @autopost_params = autopost_params
      @event_dispatcher = event_dispatcher
    end

    def self.call(...)
      new(...).call
    end

    def call
      user.rate_limiter.check_limit!(:autopost_update)

      # Grab the state of the autopost's "publish" status before making any further updates to it.
      was_previously_published = autopost.published

      # updated edited time only if already published and not edited by an admin
      update_edited_at = autopost.user == user && autopost.published
      attrs = Autoposts::Attributes.new(autopost_params, autopost.user).for_update(update_edited_at: update_edited_at)

      success = autopost.update(attrs)

      if success
        user.rate_limiter.track_limit_by_action(:autopost_update)

        # if autopost.published && autopost.saved_change_to_published_at.present?

        # elsif autopost.published

        # end

        # Remove any associated notifications if Autopost is unpublished
        if autopost.saved_changes["published"] == [true, false]
          Notification.remove_all_by_action_without_delay(notifiable_ids: autopost.id, notifiable_type: "Autopost",
                                                          action: "Published")
        end

        # Do not notify if the autopost was previously already in a published state or is continually unpublished.
        dispatch_event(autopost) if autopost.published || was_previously_published
      end
      Result.new(success: success, autopost: autopost.decorate)
    end

    private

    attr_reader :user, :autopost, :autopost_params, :event_dispatcher

    def dispatch_event(autopost)
      event_dispatcher.call("autopost_updated", autopost)
    end
  end
end
