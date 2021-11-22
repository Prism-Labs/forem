import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { Header } from './Header';
import { articlePropTypes } from './articlePropTypes';

export class SingleArticle extends Component {

  constructor(props) {
    super(props);
    const { article } = this.props;
    this.state = {
      article,
    };
  }

  componentDidMount() {
    if (!this.state.article.processed_html) {
      const { article } = this.props;
      this.loadRenderedArticle(article);
      this.loadAuthor(article);
    }
  }

  async _callJsonAPI(url) {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    });
    return await response.json();
  }

  /**
   * Articles can't not be rendered purely on the client-side, but needs server-side help.
   * It's because some features like "liquid tags" are only supported on the server-side.
   */
  async loadRenderedArticle(article) {
    const json = await this._callJsonAPI(`/api/articles${article.path}`);

    // assign new attributes
    Object.assign(article, {...json, processed_html: json.body_html });

    this.setState({
      article: { ...article, ...json }
    })
  }

  async loadAuthor(article) {
    const json = await this._callJsonAPI(`/api/users/${article.user_id}`);

    // assign new attributes
    Object.assign(article.user, json);
    this.setState({
      article: { ...article, user: json }
    })
  }

  articleAuthor = (article) => {
    const { user = {} } = article;
    const { username, name, profile_image_90, profile_image } = user;
    return (
      <div className="fs-s flex items-center">
        <a
          href={`/${username}`}
          className="crayons-avatar crayons-avatar--l mr-2"
        >
          <img
            src={profile_image_90 || profile_image}
            alt={name}
            width="32"
            height="32"
            className="crayons-avatar__image"
            loading="lazy"
          />
        </a>
  
        <div>
          <a href={`/${username}`} className="crayons-link fw-medium">
            {name}
          </a>
        </div>
      </div>
    );
  }

  articleContent = (
    article,
    currentUserId,
    onOpenModal,
    isModal = false,
  ) => {
    return (
      <div className="relative">
        <Header
          article={article}
          currentUserId={currentUserId}
          isModal={isModal}
          onOpenModal={onOpenModal}
        />
        { this.articleAuthor(article) }
        <div
          className="my-4"
          dangerouslySetInnerHTML={{ __html: article.processed_html }} // eslint-disable-line react/no-danger
        />
      </div>
    );
  };

  articleInline = (
    article,
    currentUserId,
    onOpenModal,
  ) => {
    return (
      <div
        className="single-article relative crayons-card"
        id={`single-article-${article.id}`}
        data-testid={`single-article-${article.id}`}
      >
        <div className="article-content p-4">
          {this.articleContent(
            article,
            currentUserId,
            onOpenModal,
          )}
        </div>
      </div>
    );
  };

  assetUrl = (path) => {
    return `/assets/${path}`;
  }

  articleUrl = (article) => {
    return article.canonical_url || `${location.protocol}://${location.host}/${article.path}`;
  }

  articleReactionButton = (
    article,
    category,
    currentUserId,
    description,
    image_path,
    image_active_path,
    aria_label,
  ) => {
    return (
      <button
        id={`reaction-butt-${category}`}
        aria-label={aria_label}
        aria-pressed="false"
        className={`crayons-reaction crayons-reaction--${category}`}
        data-category={category}
        title={description}>
        <span className="crayons-reaction__icon crayons-reaction__icon--inactive">
          <img src={this.assetUrl(image_path)} aria-hidden="true" className="crayons-icon" alt="" />
        </span>
        {
          currentUserId ? ( //We cannot trigger the action state unless the user is signed in, so no need to render.
            <span className="crayons-reaction__icon crayons-reaction__icon--active">
              <img src={this.assetUrl(image_active_path)} aria-hidden="true" className="crayons-icon" alt="" />
            </span>
          ) : undefined
        }
        <span className="crayons-reaction__count" id={`reaction-number-${category}`}>
          <span className="bg-base-40 opacity-25 p-2 inline-block radius-default"/>
        </span>
      </button>
    )
  }

  articleSideBar = (
    article,
    currentUserId
  ) => {
    return (
      <div className="relative">
        <div className="crayons-article-actions print-hidden">
          <div className="crayons-article-actions__inner">
            {this.articleReactionButton(
              article,
              'like',
              currentUserId,
              "Heart",
              "heart.svg",
              "heart-filled.svg",
              "Like"
            )}
            {this.articleReactionButton(
              article,
              'unicorn',
              currentUserId,
              "Unicorn",
              "unicorn.svg",
              "unicorn-filled.svg",
              "React with unicorn"
            )}
            {this.articleReactionButton(
              article,
              'readinglist',
              currentUserId,
              "Save",
              "save.svg",
              "save-filled.svg",
              "Add to reading listn"
            )}

            <div className="align-center m:relative">
              <button id="article-show-more-button" aria-controls="article-show-more-dropdown" aria-expanded="false" aria-haspopup="true" className="dropbtn crayons-btn crayons-btn--ghost-dimmed crayons-btn--icon-rounded" aria-label="Share post options">
                <img src={this.assetUrl("overflow-horizontal.svg")} aria-hidden="true" className="dropdown-icon crayons-icon" alt="" title="More..." />
              </button>

              <div id="article-show-more-dropdown" className="crayons-dropdown side-bar left-1 s:left-auto m:left-100">
                <div>
                  <button
                    id="copy-post-url-button"
                    className="flex justify-between crayons-link crayons-link--block w-100 bg-transparent border-0"
                    data-postUrl={this.articleUrl(article)}>
                    <span className="fw-bold">Copy Post URL</span>
                    <img src="/assets/copy.svg" aria-hidden="true" id="article-copy-icon" className="crayons-icon mx-2 shrink-0" alt="" title="Copy article link to the clipboard" />
                  </button>
                  <div id="article-copy-link-announcer" aria-live="polite" className="crayons-notice crayons-notice--success my-2 p-1" hidden>Copied to Clipboard</div>
                </div>

                <div className="Desktop-only">
                  <a
                    target="_blank"
                    className="crayons-link crayons-link--block"
                    rel="noreferrer"
                    href={`https://twitter.com/intent/tweet?text=${article.title} by ${article.user.twitter_username ? article.user.twitter_username : article.user.name} ${this.articleUrl(article)}`}>
                    Share to Twitter
                  </a>
                  <a
                    target="_blank"
                    className="crayons-link crayons-link--block"
                    rel="noreferrer"
                    href={`https://www.linkedin.com/shareArticle?mini=true&url=${this.articleUrl(article)}&title=${article.title}&summary=${article.description}&source=${window.community_name}`}>
                    Share to LinkedIn
                  </a>
                  <a
                    target="_blank"
                    className="crayons-link crayons-link--block"
                    rel="noreferrer"
                    href={`https://www.reddit.com/submit?url=${this.articleUrl(article)}&title=${article.title}`}>
                    Share to Reddit
                  </a>
                  <a
                    target="_blank"
                    className="crayons-link crayons-link--block"
                    rel="noreferrer"
                    href={`https://news.ycombinator.com/submitlink?u=${this.articleUrl(article)}&t=${article.title}`}>
                    Share to Hacker News
                  </a>
                  <a
                    target="_blank"
                    className="crayons-link crayons-link--block"
                    rel="noreferrer"
                    href={`https://www.facebook.com/sharer.php?u=${this.articleUrl(article)}`}>
                    Share to Facebook
                  </a>
                </div>

                <web-share-wrapper shareurl={this.articleUrl(article)} sharetitle={article.title} sharetext={article.description} template="web-share-button" />

                <template id="web-share-button">
                  <a href="#" className="dropdown-link-row crayons-link crayons-link--block">Share Post via...</a>
                </template>

                <a href="/report-abuse" className="crayons-link crayons-link--block">Report Abuse</a>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  };

  profileCardContent = (actor) => {
    let profile_detail, logo_class, avatar_class;
    if (actor.class_name == "User") {
      logo_class = "crayons-avatar crayons-avatar--xl";
      avatar_class = "crayons-avatar__image";
      profile_detail = (
        <div className="user-metadata-details">
          <ul className="user-metadata-details-inner">
            { actor.profile_location && (
              <li>
                <div className="key">
                  Location
                </div>
                <div className="value">
                  {actor.profile_location}
                </div>
              </li>
            )}
            {/* <% if (header_fields = actor.profile.decorate.ui_attributes_for(area: :header)).present? %>
              <% header_fields.sort.each do |title, value| %>
                <li>
                  <div className="key">
                    <%= title %>
                  </div>
                  <div className="value">
                    <%= value %>
                  </div>
                </li>
              <% end %>
            <% end %> */}
            <li>
              <div className="key">
                Joined
              </div>
              <div className="value">
                {/* {local_date(actor.created_at)} */}
              </div>
            </li>
          </ul>
        </div>
      );
    }
    else if(actor.class_name == "Organization" && actor.approved_and_filled_out_cta) {
      logo_class = "crayons-logo crayons-logo--xl";
      avatar_class = "crayons-logo__imag";
      profile_detail = (
        <>
          <div>
            {actor.cta_processed_html}
          </div>

          { actor.cta_button_text && actor.cta_button_url && (
            <div>
              <a href={actor.cta_button_url || "Learn more"} className="crayons-btn crayons-btn--outlined w-100">
                {actor.cta_button_text}
              </a>
            </div>
          )}
        </>
      );
    }

    return (
      <div>
        <div className="-mt-4">
          <a href={actor.path} className="flex">
            <span className={`${logo_class} mr-2 shrink-0`}>
              <img src={actor.profile_image_90 || actor.profile_image} className={avatar_class} alt="" loading="lazy" />
            </span>
            <span className="crayons-link crayons-subtitle-2 mt-5">{actor.name}</span>
          </a>
        </div>

        <div className="print-hidden">
          {/* {follow_button(actor, style = "", classes = "w-100")} */}
        </div>

        {
          actor.tag_line && (
            <div className="color-base-70">
              { actor.tag_line || actor.summary || "Posts in this tag" }
            </div>
          )
        }

        { profile_detail }
      </div>
    )
  };

  articleSideBarRight = (
    article,
  ) => {
    const actor = {
      ...(article.organization || article.user),
      class_name: article.organization ? 'Organization' : 'User',
    };

    return (
      <div className="crayons-article-sticky grid gap-4 break-word" id="article-show-primary-sticky-nav">
        <div className="crayons-card crayons-card--secondary branded-7 p-4 pt-0 gap-4 grid">
          { this.profileCardContent(actor) }
        </div>
      </div>
    )
  }

  articleModal = (
    article,
    currentUserId,
    onOpenModal,
  ) => {
    return (
      <div
        className="single-article relative crayons-layout crayons-layout--3-cols crayons-layout--article"
        id={`single-article-${article.id}`}
        data-testid={`single-article-${article.id}`}
      >
        <aside className="crayons-layout__sidebar-left" aria-label="Article actions">
          {this.articleSideBar(article, currentUserId)}
        </aside>
        <div className="article-content px-3">
          {this.articleContent(
            article,
            currentUserId,
            onOpenModal,
            true,
          )}
        </div>
        <aside className="crayons-layout__sidebar-right" aria-label="Author details">
          {this.articleSideBarRight(article)}
        </aside>
      </div>
    );
  };

  render() {
    const {
      currentUserId,
      onOpenModal,
      isOpen,
    } = this.props;
    return isOpen
      ? this.articleModal(
          this.state.article,
          currentUserId,
          onOpenModal,
        )
      : this.articleInline(
        this.state.article,
          currentUserId,
          onOpenModal,
        );
  }
}

SingleArticle.propTypes = {
  article: articlePropTypes.isRequired,
  onOpenModal: PropTypes.func.isRequired,
  isOpen: PropTypes.bool.isRequired,
  currentUserId: PropTypes.number,
};

SingleArticle.defaultProps = {
  currentUserId: null,
};

SingleArticle.displayName = 'SingleArticle';
