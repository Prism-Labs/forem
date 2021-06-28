require "rails_helper"

RSpec.describe TiktokTag, type: :liquid_tag do
  context "when it is an valid Tiktok video url" do
    describe "#render" do
      let(:tiktok_video) do
        "https://www.tiktok.com/@scout2015/video/6718335390845095173"
      end

      def generate_tiktok_liquid(url)
        Liquid::Template.register_tag("tiktok", TiktokTag)
        Liquid::Template.parse("{% tiktok #{url} %}")
      end

      before do
        allow(HTTParty).to receive(:get).and_return({
          "version": "1.0",
          "type": "video",
          "title": "Scramble up ur name & I’ll try to guess it😍❤️ #foryoupage #petsoftiktok #aesthetic",
          "author_url": "https://www.tiktok.com/@scout2015",
          "author_name": "Scout & Suki",
          "width": "100%",
          "height": "100%",
          "html": "<blockquote class=\"tiktok-embed\" cite=\"https://www.tiktok.com/@scout2015/video/6718335390845095173\" data-video-id=\"6718335390845095173\" style=\"max-width: 605px;min-width: 325px;\" > <section> <a target=\"_blank\" title=\"@scout2015\" href=\"https://www.tiktok.com/@scout2015\">@scout2015</a> <p>Scramble up ur name & I’ll try to guess it😍❤️ <a title=\"foryoupage\" target=\"_blank\" href=\"https://www.tiktok.com/tag/foryoupage\">#foryoupage</a> <a title=\"petsoftiktok\" target=\"_blank\" href=\"https://www.tiktok.com/tag/petsoftiktok\">#petsoftiktok</a> <a title=\"aesthetic\" target=\"_blank\" href=\"https://www.tiktok.com/tag/aesthetic\">#aesthetic</a></p> <a target=\"_blank\" title=\"♬ original sound - 𝐇𝐚𝐰𝐚𝐢𝐢𓆉\" href=\"https://www.tiktok.com/music/original-sound-6689804660171082501\">♬ original sound - 𝐇𝐚𝐰𝐚𝐢𝐢𓆉</a> </section> </blockquote> <script async src=\"https://www.tiktok.com/embed.js\"></script>",
          "thumbnail_width": 720,
          "thumbnail_height": 1280,
          "thumbnail_url": "https://p16.muscdn.com/obj/tos-maliva-p-0068/06kv6rfcesljdjr45ukb0000d844090v0200010605",
          "provider_url": "https://www.tiktok.com",
          "provider_name": "TikTok"
        })
      end

      it "renders tiktok content" do
        tiktok_liquid = generate_tiktok_liquid(tiktok_video)
        expect(tiktok_liquid.render).to include("tiktok-embed")
      end
    end
  end
end
