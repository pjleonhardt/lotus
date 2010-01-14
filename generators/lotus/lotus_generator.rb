class LotusGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.file 'initializer.rb', "config/initializers/lotus.rb"
      m.file "query_builder.js", "public/javascripts/query_builder.js"
    end
  end
end
