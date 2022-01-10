class AddCronAttrsToAutoposts < ActiveRecord::Migration[6.1]
  def change
    # crontab expression
    #     *    *    *   *    *
    #     |    |    |    |   |
    #     |    |    |    |    Day of the Week ( 0 - 6 ) ( Sunday = 0 )
    #     |    |    |    Month ( 1 - 12 )
    #     |    |    Day of Month ( 1 - 31 )
    #     |    Hour ( 0 - 23 )
    #     Min ( 0 - 59 )
    add_column :autoposts, :article_create_crontab, :string, default: "0 0 * * *" # every day at 00:00
    add_column :autoposts, :article_update_crontab, :string, default: "55 23 * * *" # every day at 23:55 before new article is posted
    # number of maximum articles to be posted based on this autopost template
    add_column :autoposts, :max_articles_count, :integer, default: 0
  end
end
