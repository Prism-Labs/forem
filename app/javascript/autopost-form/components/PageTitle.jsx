import { h } from 'preact';
import PropTypes from 'prop-types';
import { OrganizationPicker } from '../../organization/OrganizationPicker';

export const PageTitle = ({ organizations, organizationId, onToggle }) => {
  return (
    <div className="crayons-field__label flex items-center flex-1">
      <span className="hidden s:inline-block mr-2 whitespace-nowrap">
        Create Autopost
      </span>
      {organizations && organizations.length > 0 && (
        <div>
          <OrganizationPicker
            name="autopost[organization_id]"
            id="autopost_publish_under_org"
            className="crayons-select mt-0"
            organizations={organizations}
            organizationId={organizationId}
            onToggle={onToggle}
            emptyLabel="Personal"
          />
        </div>
      )}
    </div>
  );
};

PageTitle.propTypes = {
  organizations: PropTypes.arrayOf(PropTypes.string).isRequired,
  organizationId: PropTypes.string,
  onToggle: PropTypes.func.isRequired,
};

PageTitle.displayName = 'Organization';
