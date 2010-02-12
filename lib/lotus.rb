#== Purpose
# A general purpose 3-tuple search & where clause constraint specification object, it allows you
# to represent the various AND or OR sql where clause constraints that can be used in conjunction with ActiveRecord or
# direct SQL queries.
#
# It allows representations of queries in json and xml (via Lotus::Condition.from_params and Lotus::Condition.from_xml)
# 
# It spits out sql via Lotus::Condition.to_sql, see that class for more details
#
class Lotus
  cattr_accessor :unicorns
  cattr_accessor :case_sensitive
 
  # The configure method to be used in the lotus initializer
  # Use like:
  #   Lotus.configure do |config|
  #     config.resource :model_to_search do |r|
  #       r.default_operators = {:like => "like", :is => "Is", :fulltext => "contains"}
  #       r.add_criterion :searchable_attribute, :display => "Friendly Name"
  #       r.add_criterion :other_attribute
  #     end
  #   end
  # 
  def self.configure
    self.unicorns = []
    self.case_sensitive = false
    
    begin
      yield self
    rescue ActiveRecord::StatementInvalid; end

    self.do_magic!
    self
  end
  
  # Add a New Searchable Resource to LOTUS. Each lotus form is bound to one resource.
  # 
  # Once you have a resource, you will need to specify its search criteria
  # 
  def self.resource(name, &config_block)
    foal = Unicorn.new(name)
    yield foal
    self.unicorns << foal
  end

  def self.do_magic!
    # Inject View Helpers
    ActionView::Base.send(:include, LotusViewHelpers)
  end

  # A Unicorn is the resource for a Lotus Form. This model is used to store 
  # the components of the resource you are searching. All of the attributes are set
  # via the configure method. 
  # 
  # It is intended that this is an internal model, you should not need to interface with it.
  # 
  class Unicorn
    attr_accessor :name
    attr_accessor :criteria
    attr_accessor :default_operators
    attr_accessor :default_type

    def initialize(name)
      self.name = name
      self.criteria = []
      self.default_operators = {}
      self.default_type = :text
    end

    # Add a search criterion to show up on the Lotus Form
    #
    def add_criterion(criterion_name, options = {})
      operators    = options.delete(:operators) || self.default_operators
      display_name = options.delete(:display)   || criterion_name.to_s.titleize
      type         = options.delete(:type)      || self.default_type
      choices      = options.delete(:choices)   || {}
      criteria << Criterion.new(criterion_name, display_name, operators, type, choices)
    end
    
    # A Criterion is an attribute, real or virtual, associated with the resource you are searching. 
    # The name is what will be passed in the search, the display will be what the user is shown for the name, and the operators
    # are things like, "equals", "less than", "like", "contains", etc...
    #
    class Criterion
      attr_accessor :name, :display, :operators, :type, :choices
      
      def initialize(name, display, operators, type, choices)
        self.name = name
        self.display   = display
        self.operators = operators
        self.type      = type
        self.choices   = choices
      end
    end
  end
end
