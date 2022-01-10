module Api
  module V0
    class AutopostsController < ApiController
      before_action :authenticate!, only: %i[create update me]

      before_action :validate_autopost_param_is_hash, only: %w[create update]

      before_action :set_cache_control_headers, only: %i[index show show_by_slug]

      skip_before_action :verify_authenticity_token, only: %i[create update]

      INDEX_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id user_id organization_id collection_id
        title description main_image published_at crossposted_at social_image
        cached_tag_list slug path canonical_url comments_count
        public_reactions_count created_at edited_at last_comment_at published
        updated_at video_thumbnail_url reading_time
      ].freeze

      SHOW_ATTRIBUTES_FOR_SERIALIZATION = [
        *INDEX_ATTRIBUTES_FOR_SERIALIZATION, :body_markdown, :processed_html
      ].freeze
      private_constant :SHOW_ATTRIBUTES_FOR_SERIALIZATION

      ME_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id user_id organization_id
        title description main_image published published_at cached_tag_list
        slug path canonical_url comments_count public_reactions_count
        page_views_count crossposted_at body_markdown updated_at reading_time
      ].freeze
      private_constant :ME_ATTRIBUTES_FOR_SERIALIZATION

      def index
        @autoposts = AutopostApiIndexService.new(params).get
        @autoposts = @autoposts.select(INDEX_ATTRIBUTES_FOR_SERIALIZATION).decorate

        set_surrogate_key_header Autopost.table_key, @autoposts.map(&:record_key)
      end

      def show
        @autopost = Autopost.published
          .includes(user: :profile)
          .select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
          .find(params[:id])
          .decorate

        set_surrogate_key_header @autopost.record_key
      end

      def show_by_slug
        @autopost = Autopost.published
          .select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
          .find_by!(path: "/#{params[:username]}/#{params[:slug]}")
          .decorate

        set_surrogate_key_header @autopost.record_key
        render "show"
      end

      def create
        @autopost = Autoposts::Creator.call(@user, autopost_params).decorate

        if @autopost.persisted?
          render "show", status: :created, location: @autopost.url
        else
          message = @autopost.errors_as_sentence
          render json: { error: message, status: 422 }, status: :unprocessable_entity
        end
      end

      def update
        autoposts_relation = @user.has_role?(:super_admin) ? Autopost.includes(:user) : @user.autoposts
        autopost = autoposts_relation.find(params[:id])

        result = Autoposts::Updater.call(@user, autopost, autopost_params)

        @autopost = result.autopost

        if result.success
          render "show", status: :ok
        else
          message = @autopost.errors_as_sentence
          render json: { error: message, status: 422 }, status: :unprocessable_entity
        end
      end

      def me
        per_page = (params[:per_page] || 30).to_i
        num = [per_page, 1000].min

        @autoposts = case params[:status]
                    when "published"
                      @user.autoposts.published
                    when "unpublished"
                      @user.autoposts.unpublished
                    when "all"
                      @user.autoposts
                    else
                      @user.autoposts.published
                    end

        @autoposts = @autoposts
          .includes(:organization)
          .select(ME_ATTRIBUTES_FOR_SERIALIZATION)
          .order(published_at: :desc, created_at: :desc)
          .page(params[:page])
          .per(num)
          .decorate
      end

      private

      def autopost_params
        allowed_params = [
          :title, :body_markdown, :published, :series,
          :main_image, :canonical_url, :description, { tags: [] }
        ]
        allowed_params << :organization_id if params.dig("autopost", "organization_id") && allowed_to_change_org_id?
        params.require(:autopost).permit(allowed_params)
      end

      def allowed_to_change_org_id?
        potential_user = @autopost&.user || @user
        if @autopost.nil? || OrganizationMembership.exists?(user: potential_user,
                                                           organization_id: params.dig("autopost", "organization_id"))
          OrganizationMembership.exists?(user: potential_user,
                                         organization_id: params.dig("autopost", "organization_id"))
        elsif potential_user == @user
          potential_user.org_admin?(params.dig("autopost", "organization_id")) ||
            @user.any_admin?
        end
      end

      def validate_autopost_param_is_hash
        return if params.to_unsafe_h[:autopost].is_a?(Hash)

        message = "autopost param must be a JSON object. You provided autopost as a #{params[:autopost].class.name}"
        render json: { error: message, status: 422 }, status: :unprocessable_entity
      end
    end
  end
end
