group :jsonp do
  gem 'rack-jsonp', :require => 'rack/jsonp'
end if SETTINGS[:support_jsonp]
