
/**
 * 
 * @param {*} param0 
 * @param {string} path - article path
 * @returns 
 */
export function getLocation({ timeFrame = '', path }) {
    let newLocation = '';
    if (path) {
      newLocation = `/${path}`;
    } else if (timeFrame.length > 0) {
      newLocation = `/top/${timeFrame}`;
    } else {
      newLocation = '/';
    }
    return newLocation;
  }
  