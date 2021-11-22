import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { LoadingArticle } from '../LoadingArticle';
import { articlePropTypes } from './articlePropTypes';

/**
 * Component to render an article inside a modal
 */
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
    }
    else {
      // this is when the post is loaded previously
      setTimeout(() => {
        window.initializePage();
      }, 10)
    }
  }

  componentDidUpdate() {
    // this is when the post is loaded through async call
    if (this.state.article.processed_html) {
      setTimeout(() => {
        window.initializePage();
      }, 10)
    }
  }

  /**
   * Articles can't not be rendered purely on the client-side, but needs server-side help.
   * It's because some features like "liquid tags" are only supported on the server-side.
   */
  async loadRenderedArticle(article) {
    const response = await fetch(`${article.path}/modal`, {
      method: 'GET',
      headers: {
        'X-CSRF-Token': window.csrfToken
      },
      credentials: 'same-origin',
    });
    const html = await response.text()
    Object.assign(article, { processed_html: html });

    this.setState({
      article: { ...article, processed_html: html }
    })
  }

  render() {
    const {article} = this.state;

    // a little trick to initialize other javascript code after the component is rendered
    if (article.processed_html) {
      return (
        <div
          className="single-article relative"
          id={`single-article-${article.id}`}
          data-testid={`single-article-${article.id}`}
        >
          <div className="article-content px-3">
            <div className="relative">
              <div
                className="mb-4"
                dangerouslySetInnerHTML={{ __html: article.processed_html }} // eslint-disable-line react/no-danger
              />
            </div>
          </div>
        </div>
      )
    }
    
    return (
      <LoadingArticle />
    )
    
  }
}

SingleArticle.propTypes = {
  article: articlePropTypes.isRequired,
  currentUserId: PropTypes.number,
};

SingleArticle.defaultProps = {
  currentUserId: null,
};

SingleArticle.displayName = 'SingleArticle';
