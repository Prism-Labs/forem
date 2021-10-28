require "google_search_results"

class PagesController < ApplicationController
  # No authorization required for entirely public controller
  before_action :set_cache_control_headers, only: %i[show badge bounty faq robots]
  before_action :authenticate_user!, only: %i[search_new ghostwriter]

  LINE_BREAK = "\n".freeze

  def show
    @page = Page.find_by!(slug: params[:slug])
    not_found unless FeatureFlag.accessible?(@page.feature_flag_name, current_user)

    set_surrogate_key_header "show-page-#{params[:slug]}"
    render json: @page.body_json if @page.template == "json"
  end

  def about
    @page = Page.find_by(slug: "about")
    render :show if @page
    set_surrogate_key_header "about_page"
  end

  def about_listings
    @page = Page.find_by(slug: "about-listings")
    render :show if @page
    set_surrogate_key_header "about_listings_page"
  end

  def badge
    @html_variant = HtmlVariant.find_for_test([], "badge_landing_page")
    render layout: false
    set_surrogate_key_header "badge_page"
  end

  def bounty
    @page = Page.find_by(slug: "security")
    render :show if @page
    set_surrogate_key_header "bounty_page"
  end

  def code_of_conduct
    @page = Page.find_by(slug: "code-of-conduct")
    render :show if @page
    set_surrogate_key_header "code_of_conduct_page"
  end

  def community_moderation
    @page = Page.find_by(slug: "community-moderation")
    render :show if @page
    set_surrogate_key_header "community_moderation_page"
  end

  def contact
    @page = Page.find_by(slug: "contact")
    render :show if @page
    set_surrogate_key_header "contact"
  end

  def faq
    @page = Page.find_by(slug: "faq")
    render :show if @page
    set_surrogate_key_header "faq_page"
  end

  def post_a_job
    @page = Page.find_by(slug: "post-a-job")
    render :show if @page
    set_surrogate_key_header "post_a_job_page"
  end

  def privacy
    @page = Page.find_by(slug: "privacy")
    render :show if @page
    set_surrogate_key_header "privacy_page"
  end

  def tag_moderation
    @page = Page.find_by(slug: "tag-moderation")
    render :show if @page
    set_surrogate_key_header "tag_moderation_page"
  end

  def terms
    @page = Page.find_by(slug: "terms")
    render :show if @page
    set_surrogate_key_header "terms_page"
  end

  def report_abuse
    reported_url = params[:reported_url] || params[:url] || request.referer.presence
    @feedback_message = FeedbackMessage.new(
      reported_url: reported_url&.chomp("?i=i"),
    )
    render "pages/report_abuse"
  end

  def robots
    # dynamically-generated static page
    respond_to :text
    set_surrogate_key_header "robots_page"
  end

  def welcome
    redirect_daily_thread_request(Article.admin_published_with("welcome").first)
  end

  def challenge
    redirect_daily_thread_request(Article.admin_published_with("challenge").first)
  end

  def checkin
    daily_thread =
      Article
        .published
        .where(user: User.find_by(username: "codenewbiestaff"))
        .order("articles.published_at" => :desc)
        .first

    redirect_daily_thread_request(daily_thread)
  end

  def search_new
    # call SERPAPI to generate a list of suggested keywords
    params = request.query_parameters
    @autosuggests = []
    q = params[:q].to_s.strip

    if ApplicationConfig["SERP_API_KEY"].to_s.empty? || ApplicationConfig["GHOSTWRITER_API_KEY"].to_s.empty?
      raise Error, "SerpAPI and GhostWriter API configuration is not yet complete!"
    end

    unless q.empty?
      search = GoogleSearch.new(q: q, serp_api_key: ApplicationConfig["SERP_API_KEY"])
      hash_results = search.get_hash
      hash_results[:related_searches].each do |related_search|
        @autosuggests.append(related_search[:query])
      end
    end

    render "pages/ghostwriter"
  end

  def ghostwriter
    # Call GhostWriter API to generate article layout
    q = request.request_parameters.fetch("q", "")
    keywords = request.request_parameters.fetch("keywords", [])
    site = request.request_parameters.fetch("site", "")
    serp_google_tbs_qdr = req.request_parameters.fetch("serp_google_tbs_qdr", "")

    if keywords.length <= 0
      redirect_to action: "search_new", q: q
      return
    end

    gw_client = Ghostwriter::GhostwriterClient.new(ApplicationConfig["GHOSTWRITER_API_KEY"])
    status, text = gw_client.generate_with_keywords(keywords, site: site, serp_google_tbs_qdr: serp_google_tbs_qdr)

    if status == true
      title = q
      # See prefill patern: Articles::Builder
      c = :ghostwriter_article_counter
      session[c] = 0 unless session[c]
      session[c] = (1 + session[c].to_i) % 5 + 1 # let's allow max 5 articles to be cached
      k = ("ghostwriter_article_" + session[c].to_s).to_sym
      session[k] = "title:" + title + LINE_BREAK + "---" + text
      redirect_to controller: "articles", action: "new", gw_generated: session[c]
    else
      redirect_to action: "search_new", q: q, error: text.to_s
    end
  end

  private

  def redirect_daily_thread_request(daily_thread)
    if daily_thread
      redirect_to(URI.parse(daily_thread.path).path)
    else
      redirect_to(notifications_path)
    end
  end
end
