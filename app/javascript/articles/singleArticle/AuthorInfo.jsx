import PropTypes from 'prop-types';
import { h } from 'preact';
import { articlePropTypes } from './articlePropTypes';

const LocationText = ({ location }) => {
  return location ? (
    <a
      data-testid="single-article-location"
      className="crayons-link crayons-link--secondary"
      href={`/articles/?q=${location}`}
    >
      {'・'}
      {location}
    </a>
  ) : (
    ''
  );
};

LocationText.propTypes = {
  location: PropTypes.string,
};

LocationText.defaultProps = {
  location: null,
};

export const AuthorInfo = ({ article, onCategoryClick }) => {
  const { category, location, user = {} } = article;
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
        <p className="fs-xs">
          <a
            href={`/articles/${category}`}
            onClick={(e) => onCategoryClick(e, category)}
            data-no-instant
            className="crayons-link crayons-link--secondary"
          >
            {category}
          </a>
          <LocationText location={location} />
        </p>
      </div>
    </div>
  );
};

AuthorInfo.propTypes = {
  article: articlePropTypes.isRequired,
  onCategoryClick: PropTypes.func,
};

AuthorInfo.defaultProps = {
  onCategoryClick: () => {},
};
