import PropTypes from 'prop-types';
import { h } from 'preact';
import { DateTime } from '../../shared/components/dateTime';
import { TagList } from '../components/TagList';
import { articlePropTypes } from './articlePropTypes';
import { DropdownMenu } from './DropdownMenu';

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
    published_at_int,
    published_timestamp,
  } = article;
  const articleDate = published_at_int ? published_at_int : published_timestamp;

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
