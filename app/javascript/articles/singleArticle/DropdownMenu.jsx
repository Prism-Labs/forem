import PropTypes from 'prop-types';
import { h, Component, createRef } from 'preact';
import { articlePropTypes } from './articlePropTypes';
import { Button, Dropdown } from '@crayons';

const Icon = () => (
  <svg
    width="24"
    height="24"
    viewBox="0 0 24 24"
    className="crayons-icon"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path
      fill-rule="evenodd"
      clip-rule="evenodd"
      d="M7 12a2 2 0 11-4 0 2 2 0 014 0zm7 0a2 2 0 11-4 0 2 2 0 014 0zm5 2a2 2 0 100-4 2 2 0 000 4z"
    />
  </svg>
);

export class DropdownMenu extends Component {
  componentRef = createRef();

  static propTypes = {
    isOwner: PropTypes.bool.isRequired,
    article: articlePropTypes.isRequired,
  };

  render() {
    const { article, isOwner, isModal } = this.props;
    const { id, path } = article;
    const editUrl = `${path}/edit`;
    const reportUrl = `/report-abuse?url=https://dev.to/articles/${path}`;

    return (
      <div
        className="single-article__dropdown absolute right-0 top-0"
        ref={this.componentRef}
      >
        <Button
          id={`article-header-dropdown-btn-${id}-${isModal ? 'modal' : ''}`}
          variant="ghost"
          contentType="icon"
          tagName="button"
          aria-label="Listing options"
          icon={Icon}
        />
        <Dropdown
          className="absolute right-0 top-100 p-1"
          triggerButtonId={`article-header-dropdown-btn-${id}-${
            isModal ? 'modal' : ''
          }`}
          dropdownContentId={`article-header-dropdown-${id}-${
            isModal ? 'modal' : ''
          }`}
        >
          <div>
            {isOwner ? (
              <a href={editUrl} className="crayons-link crayons-link--block">
                Edit
              </a>
            ) : (
              <a href={reportUrl} className="crayons-link crayons-link--block">
                Report Abuse
              </a>
            )}
          </div>
        </Dropdown>
      </div>
    );
  }
}
