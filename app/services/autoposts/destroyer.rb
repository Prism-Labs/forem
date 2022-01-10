module Autoposts
  module Destroyer
    module_function

    def call(autopost, event_dispatcher = Webhook::DispatchEvent)
      # comments will automatically lose the connection to their autopost once `.destroy` is called,
      # due to the `dependent: nullify` clause, so to remove their notifications,
      # we need to cache the ids in advance
      autopost_comments_ids = autopost.comments.ids

      autopost.destroy!

      Notification.remove_all_without_delay(notifiable_ids: autopost.id, notifiable_type: "Autopost")

      if autopost_comments_ids.present?
        Notification.remove_all(notifiable_ids: autopost_comments_ids, notifiable_type: "Comment")
      end

      event_dispatcher.call("autopost_destroyed", autopost) if autopost.published?
    end
  end
end
