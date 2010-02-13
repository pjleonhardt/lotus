class DbBuilder::<%= class_name %>Condition < Lotus::Condition
  
  def self.matrixize_conditions(condition)
    unless condition.conditions.blank?
      condition.conditions.each do |c|
        matrixize_conditions(c)
      end
    else
      #clean up if the row is blank
      if condition.col_operator.blank?
        condition.col_name = "1"
        condition.col_operator = '='
        condition.col_value = "1"
      else
        
        # -- ADD YOUR CODE BELOW --
        #
        # Do Things Like:            
        # Add wild cards to LIKE Search
        # if(condition.col_operator.to_sym == :like)
        #  # "this is a search" => "this is a search%"
        #  condition.col_value = condition.col_value + '%'
        # end
        
        # Add Wild Cards to Fulltext Search
        # if condition.col_operator.to_sym == :fulltext
        #  # "this is a search" => "+this* +is* +a* +search*"
        #  condition.col_value.split(" ").map {|x| x = "+#{x}*" }.join(" ")
        # end
       
        # OPERATOR TRANSLATION
        condition.col_operator = self.change_operator(condition.col_operator)
      end
    end
  end
  
end