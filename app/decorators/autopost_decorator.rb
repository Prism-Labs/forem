class AutopostDecorator < ApplicationDecorator
  LONG_MARKDOWN_THRESHOLD = 900

  def current_state_path
    "/#{username}/autoposts/#{slug}"
  end

  def processed_canonical_url
    if canonical_url.present?
      canonical_url.to_s.strip
    else
      url
    end
  end

  def cached_tag_list_array
    (cached_tag_list || "").split(", ")
  end

  def url
    URL.url(path)
  end

  def title_length_classification
    if title.size > 105
      "longest"
    elsif title.size > 80
      "longer"
    elsif title.size > 60
      "long"
    elsif title.size > 22
      "medium"
    else
      "short"
    end
  end

  def published_at_int
    published_at.to_i
  end

  def title_with_query_preamble(_user_signed_in)
    title
  end

  def description_and_tags
    return search_optimized_description_replacement if search_optimized_description_replacement.present?

    modified_description = description.strip
    modified_description += "." unless description.end_with?(".")
    return modified_description if cached_tag_list.blank?

    modified_description + " Tagged with #{cached_tag_list}."
  end

  def video_metadata
    {
      id: id,
      video_code: video_code,
      video_source_url: video_source_url,
      video_thumbnail_url: cloudinary_video_url,
      video_closed_caption_track_url: video_closed_caption_track_url
    }
  end

  def long_markdown?
    body_markdown.present? && body_markdown.size > LONG_MARKDOWN_THRESHOLD
  end
end
