class AutopostsController < ApplicationController
  include ApplicationHelper

  before_action :authenticate_user!, except: %i[feed new]
  before_action :set_autopost, only: %i[edit manage update destroy stats admin_unpublish]
  before_action :raise_suspended, only: %i[new create update]
  before_action :set_cache_control_headers, only: %i[feed]
  after_action :verify_authorized

  def feed
    skip_authorization

    @autoposts = Autopost.all.order(published_at: :desc).page(params[:page].to_i).per(12)
    @autoposts = if params[:username]
                  handle_user_or_organization_feed
                elsif params[:tag]
                  handle_tag_feed
                else
                  @autoposts
                    .includes(:user)
                end

    not_found unless @autoposts&.any?

    set_cache_control_headers(10.minutes.to_i, stale_while_revalidate: 30, stale_if_error: 1.day.to_i)

    render layout: false, locals: {
      autoposts: @autoposts,
      user: @user,
      tag: @tag,
      allowed_tags: MarkdownProcessor::AllowedTags::FEED,
      allowed_attributes: MarkdownProcessor::AllowedAttributes::FEED
    }
  end

  def new
    base_editor_assignments

    @autopost, needs_authorization = Autoposts::Builder.call(@user, @tag, @prefill)

    if needs_authorization
      authorize(Autopost)
    else
      skip_authorization
      store_location_for(:user, request.path)
    end
  end

  def edit
    authorize @autopost

    @version = @autopost.has_frontmatter? ? "v1" : "v2"
    @user = @autopost.user
    @organizations = @user&.organizations
    @user_approved_liquid_tags = Users::ApprovedLiquidTags.call(@user)
  end

  def manage
    authorize @autopost

    @autopost = @autopost.decorate
    @user = @autopost.user
    @organizations = @user&.organizations
    # TODO: fix this for multi orgs
    @org_members = @organization.users.pluck(:name, :id) if @organization
  end

  def preview
    authorize Autopost

    begin
      fixed_body_markdown = MarkdownProcessor::Fixer::FixForPreview.call(params[:autopost_body])
      parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
      parsed_markdown = MarkdownProcessor::Parser.new(parsed.content, source: Autopost.new, user: current_user)
      processed_html = parsed_markdown.finalize
    rescue StandardError => e
      @autopost = Autopost.new(body_markdown: params[:autopost_body])
      @autopost.errors.add(:base, ErrorMessages::Clean.call(e.message))
    end

    respond_to do |format|
      if @autopost
        format.json { render json: @autopost.errors, status: :unprocessable_entity }
      else
        format.json do
          render json: {
            processed_html: processed_html,
            title: parsed["title"],
            tags: (Autopost.new.tag_list.add(parsed["tags"], parser: ActsAsTaggableOn::TagParser) if parsed["tags"]),
            cover_image: (ApplicationController.helpers.cloud_cover_url(parsed["cover_image"]) if parsed["cover_image"])
          }, status: :ok
        end
      end
    end
  end

  def create
    authorize Autopost

    @user = current_user
    autopost = Autoposts::Creator.call(@user, autopost_params_json)

    render json: if autopost.persisted?
                   { id: autopost.id, current_state_path: autopost.decorate.current_state_path }.to_json
                 else
                   autopost.errors.to_json
                 end
  end

  def update
    authorize @autopost
    @user = @autopost.user || current_user

    updated = Autoposts::Updater.call(@user, @autopost, autopost_params_json)

    respond_to do |format|
      format.html do
        # TODO: JSON should probably not be returned in the format.html section
        if autopost_params_json[:archived] && @autopost.archived # just to get archived working
          render json: @autopost.to_json(only: [:id], methods: [:current_state_path])
          return
        end
        if params[:destination]
          redirect_to(URI.parse(params[:destination]).path)
          return
        end
        if params[:autopost][:video_thumbnail_url]
          redirect_to("#{@autopost.path}/edit")
          return
        end
        render json: { status: 200 }
      end

      format.json do
        render json: if updated.success
                       @autopost.to_json(only: [:id], methods: [:current_state_path])
                     else
                       @autopost.errors.to_json
                     end
      end
    end
  end

  def delete_confirm
    @autopost = current_user.autoposts.find_by(slug: params[:slug])
    not_found unless @autopost
    authorize @autopost
  end

  def destroy
    authorize @autopost
    Autoposts::Destroyer.call(@autopost)
    respond_to do |format|
      format.html { redirect_to "/dashboard/autoposts", notice: "Autopost was successfully deleted." }
      format.json { head :no_content }
    end
  end

  def stats
    authorize @autopost
    @organization_id = @autopost.organization_id
  end

  def admin_unpublish
    authorize @autopost
    if @autopost.has_frontmatter?
      @autopost.body_markdown.sub!(/\npublished:\s*true\s*\n/, "\npublished: false\n")
    else
      @autopost.published = false
    end

    if @autopost.save
      render json: { message: "success", path: @autopost.current_state_path }, status: :ok
    else
      render json: { message: @autopost.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def base_editor_assignments
    @user = current_user
    @version = @user.setting.editor_version if @user
    @organizations = @user&.organizations
    @tag = Tag.find_by(name: params[:template])
    @prefill = params[:prefill].to_s.gsub("\\n ", "\n").gsub("\\n", "\n")
    @user_approved_liquid_tags = Users::ApprovedLiquidTags.call(@user)
  end

  def handle_user_or_organization_feed
    if (@user = User.find_by(username: params[:username]))
      Honeycomb.add_field("autoposts_route", "user")
      @autoposts = @autoposts.where(user_id: @user.id)
    elsif (@user = Organization.find_by(slug: params[:username]))
      Honeycomb.add_field("autoposts_route", "org")
      @autoposts = @autoposts.where(organization_id: @user.id).includes(:user)
    end
  end

  def handle_tag_feed
    @tag = Tag.aliased_name(params[:tag])
    return unless @tag

    @autoposts = @autoposts.cached_tagged_with(@tag)
  end

  def set_autopost
    owner = User.find_by(username: params[:username]) || Organization.find_by(slug: params[:username])
    found_autopost = if params[:slug] && owner
                      owner.autoposts.find_by(slug: params[:slug])
                    else
                      Autopost.includes(:user).find(params[:id])
                    end
    @autopost = found_autopost || not_found
    Honeycomb.add_field("autopost_id", @autopost.id)
  end

  # TODO: refactor all of this update logic into the Autoposts::Updater possibly,
  # ideally there should only be one place to handle the update logic
  def autopost_params_json
    params.require(:autopost) # to trigger the correct exception in case `:autopost` is missing

    params["autopost"].transform_keys!(&:underscore)

    allowed_params = if params["autopost"]["version"] == "v1"
                       %i[body_markdown]
                     else
                       %i[
                         title body_markdown main_image published description video_thumbnail_url
                         tag_list canonical_url series collection_id archived
                       ]
                     end

    # NOTE: the organization logic is still a little counter intuitive but this should
    # fix the bug <https://github.com/thepracticaldev/dev.to/issues/2871>
    if params["autopost"]["user_id"] && org_admin_user_change_privilege
      allowed_params << :user_id
    elsif params["autopost"]["organization_id"] && allowed_to_change_org_id?
      # change the organization of the autopost only if explicitly asked to do so
      allowed_params << :organization_id
    end

    params.require(:autopost).permit(allowed_params)
  end

  def allowed_to_change_org_id?
    potential_user = @autopost&.user || current_user
    potential_org_id = params["autopost"]["organization_id"].presence || @autopost&.organization_id
    OrganizationMembership.exists?(user: potential_user, organization_id: potential_org_id) ||
      current_user.any_admin?
  end

  def org_admin_user_change_privilege
    params[:autopost][:user_id] &&
      # if current_user is an org admin of the autopost's org
      current_user.org_admin?(@autopost.organization_id) &&
      # and if the author being changed to belongs to the autopost's org
      OrganizationMembership.exists?(user_id: params[:autopost][:user_id], organization_id: @autopost.organization_id)
  end
end
