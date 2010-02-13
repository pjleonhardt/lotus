class LotusConditionGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.template 'models/condition.rb', "app/models/#{file_name}_condition.rb"
    end
  end
end
