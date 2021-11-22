import { h } from 'preact';
import PropTypes from 'prop-types';
import { SingleArticle } from '../singleArticle/SingleArticle';
import { MessageModal } from './MessageModal';
import { Modal as CrayonsModal } from '@crayons';

export const Modal = ({
  currentUserId,
  onAddTag,
  onChangeDraftingMessage,
  onClick,
  onChangeCategory,
  onOpenModal,
  onSubmit,
  article,
  message,
}) => {
  const shouldRenderMessageModal = article && article.contact_via_connect;

  return (
    <div className="articles-modal" data-testid="articles-modal">
      <CrayonsModal
        onClose={onClick}
        closeOnClickOutside={true}
        title="&nbsp;"
      >
        <div>
          <SingleArticle
            onAddTag={onAddTag}
            onChangeCategory={onChangeCategory}
            article={article}
            currentUserId={currentUserId}
            onOpenModal={onOpenModal}
            isOpen
          />
        </div>
        {shouldRenderMessageModal && (
          <div className="bg-base-10 p-3 m:p-6 l:p-8">
            <MessageModal
              onSubmit={onSubmit}
              onChangeDraftingMessage={onChangeDraftingMessage}
              message={message}
              article={article}
            />
          </div>
        )}
      </CrayonsModal>
    </div>
  );
};

Modal.propTypes = {
  article: PropTypes.isRequired,
  onAddTag: PropTypes.func,
  onChangeDraftingMessage: PropTypes.func,
  onClick: PropTypes.func.isRequired,
  onChangeCategory: PropTypes.func,
  onOpenModal: PropTypes.func.isRequired,
  onSubmit: PropTypes.func,
  currentUserId: PropTypes.number,
  message: PropTypes.string,
};

Modal.defaultProps = {
  currentUserId: null,
};
