import { h } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../../common-prop-types';

export const ContentTitle = ({ article, noLink }) => {

  const innerContent = (
    <span>
      {article.class_name === 'PodcastEpisode' && (
        <span className="crayons-story__flare-tag">podcast</span>
      )}
      {article.class_name === 'User' && (
        <span
          className="crayons-story__flare-tag"
          style={{ background: '#5874d9', color: 'white' }}
        >
          person
        </span>
      )}
      {/* eslint-disable-next-line react/no-danger */}
      <span className="crayons-story__title-link" dangerouslySetInnerHTML={{ __html: filterXSS(article.title) }} />
    </span>
  );

  return (
    <h3 className="crayons-story__title">
      { noLink && (
        <span id={`article-link-${article.id}`}>
          {innerContent}
        </span>
      )}
      { !noLink && (
        <a href={article.path} id={`article-link-${article.id}`}>
          {innerContent}
        </a>
      )}
    </h3>
  )
};

ContentTitle.propTypes = {
  article: articlePropTypes.isRequired,
  noLink: PropTypes.bool, // do not act as a link
};

ContentTitle.displayName = 'ContentTitle';
