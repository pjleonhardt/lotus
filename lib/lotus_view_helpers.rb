module LotusViewHelpers
  
  # Creates a full featured lotus form based on the given resource. This method retuns a normal Rails form, allowing you to add arbitrary fields and
  # form elements, in addition to the Lotus search fields. To add the lotus search fields to your form, call lotus.
  # 
  # Parameters:
  # *resource*: A resource defined in the lotus initializer. 
  # *url*: The url to post the search form
  # *options*:
  # * *div_options*: Options hashed passed to div surrounding lotus block
  # * *condition*: Pass in a Lotus condition to load a saved search
  # * All other options get passed to the form method
  # *parameters_for_url*: Passed to the form method
  #
  # Requires a block passed to it, to define anything else in the form.
  # 
  # *Example:*
  #   <% lotus_form(:job_offer, '/search', {:condition => session[:condition]}) do %>
  #       <%= text_field :regular_field %>
  #       <%= lotus %>
  #       <%= submit_tag "Search!" %>
  #   <% end %>
  # 
  def lotus_form(resource, url, options = {}, *parameters_for_url, &blck)
    increment_instances
    condition = options.delete(:condition)
    @lotus_injection_tag_options = {:id => "lotusSearch_#{resource}", :class => "lotusSearch"}.merge(options.delete(:div_options) || {})
    
    qb_name = "qb_#{@lotus_instances}"
    
    options[:onSubmit] = "#{qb_name}.injectRootCondition('#{resource}');"    
    form_tag(url, options, *parameters_for_url) do
      yield +
      lotus_javascript(resource, @lotus_injection_tag_options[:id], qb_name, condition)
    end
  end
  
  # Internal method to inject the required javascript for lotus to work
  # 
  def lotus_javascript(resource, target_id, qb_name, condition = nil)
    unicorn = Lotus.unicorns.find { |u| u.name == resource }
    unicorn.criteria.each(&:preload!)
    
    str = "<script type=\"text/javascript\">
        var #{qb_name} = new QueryBuilder(
         {root: $('#{target_id}'),
          criteria: #{unicorn.criteria.to_json}"
    if(condition)
      str << ", condition: new Condition(#{condition.to_json})"
    end
    
    unicorn.criteria.each(&:unload!)
    
    str << "});
      </script>"
    return str
  end
  
  # Method used to keep track of number of instances of lotus on a page (to avoid clashing ids)
  # 
  def increment_instances
    @lotus_instances ||= 0
    @lotus_instances += 1
  end  
  
  # Injects the lotus functionality into a lotus form. 
  # 
  def lotus
    raise NoMethodError.new("Method 'lotus' must be used within a 'lotus_form'") unless @lotus_injection_tag_options.is_a? Hash
    tag("div", @lotus_injection_tag_options, true) + "</div>"
  end
  
  # Injects the lotus functionality outside of a lotus form. Not intended for normal usage.
  # 
  def lotus_tag(resource, qb_name = "qb", tag_options = {})
    tag_options = {:id => "lotusSearch_#{resource}", :class => "lotusSearch"}.merge(tag_options)
    
    tag("div", tag_options, true) + "</div>" +
    lotus_javascript(resource, tag_options[:id], qb_name)
  end
end