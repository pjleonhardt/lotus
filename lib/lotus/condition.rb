=begin
== Example usage ==
s=<<-EOS
<condition conjuction="AND">
  <conditions type="array">
    <condition conjuction="AND">
      <col_name>user_name</col_name>
      <col_operator>=</col_operator>
      <col_value>verm0032</col_value>
    </condition>
  </conditions>
</condition>
EOS
x = Lotus::Condition.from_xml(s)
x.to_sql
=> "( ( user_name = 'verm0032' ) )"


Expects:
<condition conjuction="OR">
  <conditions type="array">
    <condition conjuction="AND">
      <col_name>user_name</col_name>
      <col_operator>LIKE</col_operator>
      <col_value>verm0032</col_value>
    </condition>
    <condition conjuction="AND">
      <col_name>user_name</col_name>
      <col_operator>LIKE</col_operator>
      <col_value>goggins</col_value>
    </condition>
  </conditions>
</condition>


<condition>
  <conditions type="array">
  </conditions>
</condition>

=end
class Lotus
  class ConditionsTypeError < Exception
  end
  class OperatorNotFound < Exception
  end


  # The Condition class is where most of the magic happens. This is where the translation from the search form to MySQL occurs.
  # 
  # You are expected to extend this class with your own Condition specific to your needs. This might mean that you have a different
  # condition class for each resource defined in your initializer.
  # 
  # An example usage of this class would be:
  #   def search
  #     @c = YourCondition.from_params(params[:lotus])
  #     original_condition = YourCondition.from_params(params[:lotus])
  #     YourCondition.translate_fields(@c)
  #     if(original_condition.column_scope.include?("department"))
  #       @results = YourModel.find(:all, :conditions => @c.to_sql, :include => :department)
  #     else
  #       @results = YourModel.find(:all, :conditions => @c.to_sql)
  #     end
  #   end
  #
  # And an example of this class:
  #  class YourCondition < Lotus::Condition
  #
  #    # Here you translate the criteria from the initializer into the MySQL equivalents...
  #    #
  #    def self.translate_fields(condition)
  #      #recursively traverse the condition, for nested conditions
  #      unless condition.conditions.blank?      
  #        condition.conditions.each do |c|   
  #          translate_fields(c)
  #        end
  #      else
  #        if(condition.col_name == "all")
  #          condition.col_name = "search_cache"
  #        elsif condition.col_name == "department"
  #          condition.col_name = "departments.department_name"
  #        end
  #       
  #        # Add wilcards
  #        if(condition.col_operator == 'like')
  #          condition.col_value += "%"
  #        elsif(condition.col_operator == "fulltext")
  #          condition.col_value = condition.col_value.split().map {|x| "+{x}*"}.join(" ")
  #        end
  #        
  #        # Change Operators
  #        condition.col_operator = self.change_operator(condition.col_operator)         
  #      end
  #    
  #      def self.change_operator(op)
  #        translations = { 
  #          :ntlike => "NOT LIKE",
  #          :like   => "LIKE",
  #          :is     => "=",
  #          :not    => "!=",
  #          :gt     => ">",
  #          :lt     => "<",
  #          :fulltext   => :full 
  #        }
  #       return translations[operator.to_sym] if translations.keys.include?(operator.to_sym)
  #       raise Lotus::OperatorNotFound.new("#{operator} is not a valid operator")
  #     end
  #   end
  #    
  #    
  class Condition
    # The grammar is:
    #  Condition := Condition Conjunction Condition || Terminal
    #  Conjunction := AND || OR
    #  Terminal := [field, op, value]
    #
    # MySQL Note:
    #  ANDs are always executed before ORs unless specifically grouped by parenthesis.
    #
  
    attr_accessor :col_name, :col_value, :col_operator, :conditions, :conjunction
  
    def initialize(options = {})
      options.symbolize_keys!
      @conjunction = options.delete(:conjunction) || Condition.default_conjunction
      @conditions = options.delete(:conditions) || []
         
      resolve_conditions

      @col_name = options.delete(:col_name)
      @col_value = options.delete(:col_value)
      @col_operator = options.delete(:col_operator)
    end

    def self.default_conjunction
      "AND"
    end
    
    def blank_condition?
      if self.conditions.blank?
        if self.col_value.blank?
          return true
        elsif self.col_name == "1" and self.col_value == "1"
          return true
        end
      end
      false
    end
    
    def sanitize_conjunction(conj)      
      return conj if(conj == "AND" || conj == "OR")
      return nil
    end

    def resolve_conditions 
       raise ConditionsTypeError unless @conditions.is_a? Array
     
       conditions = []
       @conditions.each do |condition| 
         unless condition.is_a? Condition   # -- from_xml
           conditions << Condition.new(condition.symbolize_keys)# unless condition["col_operator"].blank?
         else
           conditions << condition
         end
       end
       
       conditions.delete_if {|c| c.col_operator.blank? }

       @conditions = conditions
    end

    def to_xml(options = {}) 
      xml = Builder::XmlMarkup.new(options) 
      xml.instruct! unless options[:skip_instruct]
      #xml.condition(:conjunction => @conjunction) do |root|
      xml.condition do |root|
        root.conjunction = @conjunction
        unless @conditions.blank?
          root.conditions(:type => "array") do |conditions|
            @conditions.each do |condition|
              conditions << condition.to_xml(:skip_instruct => true)
            end
          end
        else
          root.col_name  @col_name
          root.col_operator  @col_operator
          root.col_value  @col_value
        end
      end
    end

    def self.from_xml(xml)
      Condition.new(Hash.from_xml(xml).values.first.symbolize_keys)
    end
  
    def self.from_params(params, format = :json)
      if format == :json
        json = ActiveSupport::JSON.decode(params)
        return self.new(json)  
      elsif format == :xml
        return self.from_xml(params)
      end      
    end
    
    def to_sql
      sql = []
      unless @conditions.blank?
        @conditions.each do |condition|
          sql << condition.to_sql
        end
      else
        @col_name = 
        unless @col_value.blank? # Allow For IS NULL        
          @col_value = @col_value.downcase unless Lotus.case_sensitive
          if @col_operator.to_sym == :full
            sql << sanitize(["MATCH (%s) AGAINST ('%s' IN BOOLEAN MODE )", @col_name, @col_value])              
          else
            sql << sanitize(["%s %s '%s'", @col_name, @col_operator, @col_value])
          end
        else
          sql << sanitize(["%s %s", @col_name, @col_operator])
        end
      end
      sql = sql.join(" #{sanitize_conjunction(@conjunction)} ")
      "( #{sql} )"
    end
    
    def sanitize(arr)
      ActiveRecord::Base.send(:sanitize_sql_array, arr)
    end
    
    def column_scope
      unless @conditions.blank?
        return [] + (@conditions.collect {|c| c.column_scope}).flatten.uniq
      else
        return [@col_name]
      end
    end
  end
end
