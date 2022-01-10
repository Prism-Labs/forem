json.array!(@autoposts) do |article|
  json.extract!(article, :id, :title, :body_html)
  json.url autopost_url(article, format: :json)
end
