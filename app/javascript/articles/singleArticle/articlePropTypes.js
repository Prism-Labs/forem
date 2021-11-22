import PropTypes from 'prop-types';

export const articlePropTypes = PropTypes.shape({
  id: PropTypes.number,
  class_name: PropTypes.string,
  cloudinary_video_url: PropTypes.string,
  comments_count: PropTypes.number,
  experience_level_rating: PropTypes.number,
  experience_level_rating_distribution: PropTypes.number,
  flare_tag: PropTypes.string,
  main_image: PropTypes.string,
  organization_id: PropTypes.number,
  path: PropTypes.string, 
  pinned: PropTypes.bool,
  public_reactions_count: PropTypes.number,
  published_at_int: PropTypes.number,
  published_timestamp: PropTypes.string,
  readable_publish_date: PropTypes.string,
  reading_time: PropTypes.number,
  tag_list: PropTypes.arrayOf(PropTypes.string) | PropTypes.string,
  tags: PropTypes.arrayOf(PropTypes.string),
  title: PropTypes.string,
  top_comments: PropTypes.arrayOf(
    PropTypes.shape({
      name: PropTypes.string.isRequired,
      username: PropTypes.string.isRequired,
      profile_image_90: PropTypes.string,
    })
  ),
  user: PropTypes.shape({
    name: PropTypes.string.isRequired,
    profile_image_90: PropTypes.string,
    profile_image_url: PropTypes.string,
    username: PropTypes.string.isRequired,
  }),
  user_id: PropTypes.number,
  video: PropTypes.string,
  video_duration_in_minutes: PropTypes.string,
  video_thumbnail_url: PropTypes.string,
});




