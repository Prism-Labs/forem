module Admin
  class AutopostsController < Admin::ApplicationController
    layout "admin"

    after_action only: %i[update] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    AUTOPOSTS_ALLOWED_PARAMS = %i[social_image
                                 body_markdown
                                 approved
                                 email_digest_eligible
                                 main_image_background_hex_color
                                 featured_number
                                 user_id
                                 published_at
                                 article_create_freq   article_update_freq
                                 article_create_crontab   article_update_crontab
                                ].freeze

    def index
      case params[:state]
      when /top-/
        months_ago = params[:state].split("-")[1].to_i.months.ago
        @autoposts = autoposts_top(months_ago)
      when "chronological"
        @autoposts = autoposts_chronological
      else
        @autoposts = autoposts_mixed
      end
    end

    def show
      @autopost = Autopost.find(params[:id])
    end

    def update
      autopost = Autopost.find(params[:id])

      if autopost.update(autopost_params)
        flash[:success] = "Autopost saved!"
      else
        flash[:danger] = autopost.errors_as_sentence
      end

      redirect_to admin_autopost_path(autopost.id)
    end

    private

    def autoposts_top(months_ago)
      Autopost.published
        .where("published_at > ?", months_ago)
        .includes(user: [:notes])
        .limited_columns_internal_select
        .page(params[:page])
        .per(50)
    end

    def autoposts_chronological
      Autopost.published
        .includes(user: [:notes])
        .limited_columns_internal_select
        .order(published_at: :desc)
        .page(params[:page])
        .per(50)
    end

    def autoposts_mixed
      Autopost.published
        .includes(user: [:notes])
        .limited_columns_internal_select
        .page(params[:page])
        .per(30)
    end

    def autopost_params
      params.require(:autopost).permit(AUTOPOSTS_ALLOWED_PARAMS)
    end

    def authorize_admin
      authorize Autopost, :access?, policy_class: InternalPolicy
    end
  end
end
