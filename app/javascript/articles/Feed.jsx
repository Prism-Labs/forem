import { h } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { ListNavigation } from '../shared/components/useListNavigation';
import { KeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';
import { useMediaQuery, BREAKPOINTS } from '../shared/components/useMediaQuery';
import { getLocation } from './utils';
import { Modal } from './components/Modal';

/* global userData sendHapticMessage showLoginModal buttonFormData renderNewSidebarCount */

export const Feed = ({ timeFrame, renderFeed }) => {
  const { reading_list_ids = [] } = userData(); // eslint-disable-line camelcase
  const [bookmarkedFeedItems, setBookmarkedFeedItems] = useState(
    new Set(reading_list_ids),
  );
  const [pinnedArticle, setPinnedArticle] = useState(null);
  const [feedItems, setFeedItems] = useState([]);
  const [podcastEpisodes, setPodcastEpisodes] = useState([]);
  const [onError, setOnError] = useState(false);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalArticle, setModalArticle] = useState(null);

  const [currentUserId, setCurrentUserId] = useState(null);

  useEffect(() => {
    setPodcastEpisodes(getPodcastEpisodes());
  }, []);

  useEffect(() => {
    const keydownEventHandler = (event) => {
      if ((event.key.toLowerCase() == 'arrowleft' || event.key.toLowerCase() == 'arrowright') && isModalOpen && modalArticle) {
        event.preventDefault();
        event.stopPropagation();

        setIsModalOpen(false);
        // show previous article on the modal

        let newModalArticle;

        if (event.key.toLowerCase() == 'arrowleft') {
          if (pinnedArticle && modalArticle === pinnedArticle) {
            // reached the first one
            newModalArticle = null;
          }
          else if(feedItems.length > 0 && modalArticle === feedItems[0]) {
            newModalArticle = pinnedArticle ? pinnedArticle : null;
          }
          else if(feedItems.length > 0) {
            const idx = feedItems.indexOf(modalArticle);
            newModalArticle = feedItems[idx - 1];
          }
        }
        else if (event.key.toLowerCase() == 'arrowright') {
          if (pinnedArticle && modalArticle === pinnedArticle && feedItems.length > 0) {
            newModalArticle = feedItems[0];
          }
          else if(feedItems.length > 0 && modalArticle === feedItems[feedItems.length - 1]) {
            // already reached the end
            newModalArticle = null;
          }
          else if(feedItems.length > 0) {
            const idx = feedItems.indexOf(modalArticle);
            newModalArticle = feedItems[idx + 1];
          }
        }

        setModalArticle(newModalArticle);
        if (newModalArticle) {
          setTimeout(() => {
            setIsModalOpen(true);
          })
        }
        
      }
    };

    window.addEventListener('keydown', keydownEventHandler);

    return () => {
      window.removeEventListener('keydown', keydownEventHandler);
    };
  }, [isModalOpen, modalArticle, feedItems, pinnedArticle]);

  useEffect(() => {
    const fetchFeedItems = async () => {
      try {
        if (onError) setOnError(false);

        const feedItems = await getFeedItems(timeFrame);

        // Here we extract from the feed two special items: pinned and featured

        const pinnedArticle = feedItems.find((story) => story.pinned === true);

        // Ensure first article is one with a main_image
        // This is important because the featuredStory will
        // appear at the top of the feed, with a larger
        // main_image than any of the stories or feed elements.
        const featuredStory = feedItems.find(
          (story) => story.main_image !== null,
        );

        // If pinned and featured article aren't the same,
        // (either because featuredStory is missing or because they represent two different articles),
        // we set the pinnedArticle and remove it from feedItems.
        // If pinned and featured are the same, we just remove it from feedItems without setting it as state.
        if (pinnedArticle) {
          const index = feedItems.findIndex(
            (item) => item.id === pinnedArticle.id,
          );
          feedItems.splice(index, 1);

          if (pinnedArticle.id !== featuredStory?.id) {
            setPinnedArticle(pinnedArticle);
          }
        }

        // Remove that first story from the array to
        // prevent it from rendering twice in the feed.
        const index = feedItems.indexOf(featuredStory);
        const deleteCount = featuredStory ? 1 : 0;
        feedItems.splice(index, deleteCount);
        const subStories = feedItems;
        const organizedFeedItems = [featuredStory, subStories].flat();

        setFeedItems(organizedFeedItems);
      } catch {
        if (!onError) setOnError(true);
      }
    };

    fetchFeedItems();
  }, [timeFrame, onError]);

  setUser();

  /**
   * Retrieves feed data.
   *
   * @param {number} [page=1] Page of feed data to retrieve
   *
   * @returns {Promise} A promise containing the JSON response for the feed data.
   */
  async function getFeedItems(timeFrame = '', page = 1) {
    const response = await fetch(`/stories/feed/${timeFrame}?page=${page}`, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    });
    return await response.json();
  }

  function getPodcastEpisodes() {
    const el = document.getElementById('followed-podcasts');
    const user = userData(); // Global
    const episodes = [];
    if (
      user &&
      user.followed_podcast_ids &&
      user.followed_podcast_ids.length > 0
    ) {
      const data = JSON.parse(el.dataset.episodes);
      data.forEach((episode) => {
        if (user.followed_podcast_ids.indexOf(episode.podcast.id) > -1) {
          episodes.push(episode);
        }
      });
    }
    return episodes;
  }

  /**
   * Dispatches a click event to bookmark/unbookmark an article.
   *
   * @param {Event} event
   */
  async function bookmarkClick(event) {
    // The assumption is that the user is logged on at this point.
    const { userStatus } = document.body;
    event.preventDefault();
    sendHapticMessage('medium');

    if (userStatus === 'logged-out') {
      showLoginModal();
      return;
    }

    const { currentTarget: button } = event;
    const data = buttonFormData(button);

    const csrfToken = await getCsrfToken();
    if (!csrfToken) return;

    const fetchCallback = sendFetch('reaction-creation', data);
    const response = await fetchCallback(csrfToken);
    if (response.status === 200) {
      const json = await response.json();
      const articleId = Number(button.dataset.reactableId);

      const { result } = json;
      const updatedBookmarkedFeedItems = new Set([
        ...bookmarkedFeedItems.values(),
      ]);

      if (result === 'create') {
        updatedBookmarkedFeedItems.add(articleId);
      }

      if (result === 'destroy') {
        updatedBookmarkedFeedItems.delete(articleId);
      }

      renderNewSidebarCount(button, json);

      setBookmarkedFeedItems(updatedBookmarkedFeedItems);
    }
  }

  /**
   * Open Article Modal
   */
  function handleOpenModal(article) {
    window.console.log('handleOpenModal', article);
    setLocation(timeFrame, article.path);
    setModalArticle(article);
    setIsModalOpen(true);
  };

  /**
   * Close Article Modal
   */
  function handleCloseModal() {
    if (isModalOpen) {
      window.console.log('handleCloseModal');
      setIsModalOpen(false);
      setLocation(timeFrame, null);
    }
  }

  function setLocation(timeFrame, path) {
    const newLocation = getLocation({ timeFrame, path });
    window.history.replaceState(null, null, newLocation);
  }

  function setUser() {
    setTimeout(() => {
      if (window.currentUser && currentUserId === null) {
        setCurrentUserId(window.currentUser.id);
      }
    }, 1000);
  }

  const shortcuts = {
    b: (event) => {
      const article = event.target?.closest('article.crayons-story');

      if (!article) return;

      article.querySelector('button[id^=article-save-button]')?.click();
    }
  };

  const shouldRenderModal = isModalOpen && modalArticle;
  const isSmallScreen = useMediaQuery(`(max-width: ${BREAKPOINTS.Small}px)`);

  return (
    <div id="rendered-article-feed">
      {onError ? (
        <div class="crayons-notice crayons-notice--danger">
          There was a problem fetching your feed.
        </div>
      ) : (
        renderFeed({
          pinnedArticle,
          feedItems,
          podcastEpisodes,
          bookmarkedFeedItems,
          bookmarkClick,
          onOpenModal: isSmallScreen ? null : handleOpenModal, // let's disable article modal for small screens
        })
      )}

      <ListNavigation
          itemSelector="article.crayons-story"
          focusableSelector="a.crayons-story__hidden-navigation-link"
          waterfallItemContainerSelector="div.paged-stories" />

      <KeyboardShortcuts shortcuts={shortcuts} />

      {shouldRenderModal && (
        <Modal
          article={modalArticle}
          currentUserId={currentUserId}
          onClose={handleCloseModal}
      />
      )}
    </div>
  );
};

Feed.defaultProps = {
  timeFrame: '',
};

Feed.propTypes = {
  timeFrame: PropTypes.string,
  renderFeed: PropTypes.func.isRequired,
};

Feed.displayName = 'Feed';
