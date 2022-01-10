# encoding: UTF-8

# rubocop:disable Metrics/BlockLength

xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title user ? user.name : community_name
    xml.author user ? user.name : community_name
    xml.description user ? user.tag_line : Settings::Community.community_description
    xml.link user ? app_url(user.path) : app_url
    xml.language "en" # TODO: [yheuhtozr] support localized feeds (see #15136)
    if user
      xml.image do
        xml.url user.profile_image_90
        xml.title t("xml.user.image", user: user.name)
        xml.link app_url(user.path)
      end
    end
    articles.each do |article|
      xml.item do
        xml.title autopost.title
        xml.author(user.instance_of?(User) ? user.name : autopost.user.name)
        xml.pubDate autopost.published_at.to_s(:rfc822) if autopost.published_at
        xml.link app_url(autopost.path)
        xml.guid app_url(autopost.path)
        xml.description sanitize(autopost.plain_html, tags: allowed_tags, attributes: allowed_attributes)
        autopost.tag_list.each do |tag_name|
          xml.category tag_name
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
