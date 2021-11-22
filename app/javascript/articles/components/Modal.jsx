import { h } from 'preact';
import PropTypes from 'prop-types';
import { SingleArticle } from '../singleArticle/SingleArticle';
import { Modal as CrayonsModal } from '@crayons';

export const Modal = ({
  currentUserId,
  onClose,
  article,
}) => {
  return (
    <div id="article-modal" className="articles-modal" data-testid="articles-modal">
      <CrayonsModal
        onClose={onClose}
        closeOnClickOutside={true}
        title="&nbsp;"
      >
        <SingleArticle
          article={article}
          currentUserId={currentUserId}
        />
      </CrayonsModal>
    </div>
  );
};

Modal.propTypes = {
  article: PropTypes.isRequired,
  onClick: PropTypes.func.isRequired,
  currentUserId: PropTypes.number,
};

Modal.defaultProps = {
  currentUserId: null,
};
