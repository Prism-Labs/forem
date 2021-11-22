import PropTypes from 'prop-types';
import { h } from 'preact';
import { DateTime } from '../../shared/components/dateTime';
import { TagList } from '../components/TagList';
import { articlePropTypes } from './articlePropTypes';
import { DropdownMenu } from './DropdownMenu';

const AuthorInfo = ({
  article
}) => {
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
};

AuthorInfo.propTypes = {
  article: articlePropTypes.isRequired,
};

export const Header = ({
  article,
  currentUserId,
  isModal,
  onOpenModal
}) => {
  const {
    id,
    path,
    user_id: userId,
    title,
    published_at,
    published_timestamp,
  } = article;
  const articleDate = published_timestamp ? published_timestamp : published_at;

  return (
    <div className="mb-3">
      <h2 className="fs-4xl fw-bold lh-tight mb-1 pr-8">
        <a
          href={path}
          data-no-instant
          className="crayons-link"
          data-article-id={id}
          onClick={(event) => { !isModal && onOpenModal && (event.preventDefault(), onOpenModal()) }}
        >
          {title}
        </a>
      </h2>

      <AuthorInfo article={article} />

      <DateTime
        dateTime={new Date(articleDate)}
        className="single-article__date"
      />
      <TagList tags={article.tags || article.tag_list} />

      <DropdownMenu
        article={article}
        isOwner={currentUserId === userId}
        isModal={isModal}
      />
    </div>
  );
};

Header.propTypes = {
  article: articlePropTypes.isRequired,
  currentUserId: PropTypes.number,
};

Header.defaultProps = {
  currentUserId: null,
};
