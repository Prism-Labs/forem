import { h, render } from 'preact';
import { AutopostForm } from '../autopost-form/autopostForm';
import { Snackbar } from '../Snackbar';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function loadForm() {
  // The Snackbar for the autopost page
  const snackZone = document.getElementById('snack-zone');

  if (snackZone) {
    render(<Snackbar lifespan={3} />, snackZone);
  }

  getUserDataAndCsrfToken().then(({ currentUser, csrfToken }) => {
    window.currentUser = currentUser;
    window.csrfToken = csrfToken;

    const root = document.querySelector('main');
    const { autopost, organizations, version, siteLogo } = root.dataset;

    render(
      <AutopostForm
        autopost={autopost}
        organizations={organizations}
        version={version}
        siteLogo={siteLogo}
      />,
      root,
      root.firstElementChild,
    );
  });
}

document.ready.then(() => {
  loadForm();
  window.InstantClick.on('change', () => {
    if (document.getElementById('autopost-form')) {
      loadForm();
    }
  });
});
