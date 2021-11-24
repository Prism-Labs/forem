import { h } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../../common-prop-types';

export const ArticleCoverImage = ({ article, noLink }) => {
  if (noLink) {
    return (
      <div
        className="crayons-story__cover"
        title={article.title}
        style={{ backgroundImage: `url(${article.main_image})` }}
      >
        <span class="hidden">{article.title}</span>
      </div>
    );
  }

  return (
    <a
      href={article.path}
      className="crayons-story__cover"
      title={article.title}
      style={{ backgroundImage: `url(${article.main_image})` }}
    >
      <span class="hidden">{article.title}</span>
    </a>
  );
};

ArticleCoverImage.propTypes = {
  article: articlePropTypes.isRequired,
  noLink: PropTypes.bool, // do not act as a link
};

ArticleCoverImage.displayName = 'ArticleCoverImage';
