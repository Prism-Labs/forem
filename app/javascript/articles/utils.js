
/**
 * 
 * @param {*} param0 
 * @param {string} path - article path
 * @returns 
 */
export function getLocation({ timeFrame = '', path }) {
  let newLocation = '';
  if (path) {
    newLocation = `${path.startsWith('/') ? '' : '/'}${path}`;
  } else if (timeFrame.length > 0) {
    newLocation = `/top/${timeFrame}`;
  } else {
    newLocation = '/';
  }
  return newLocation;
}


export function articleUrl({path, url, canonical_url}) {
  if (canonical_url || url) {
    return canonical_url || url;
  }
  else if (path) {
    return `${location.protocol}://${location.host}${path}`;
  }
  return null;
}