Lotus.configure do |lotus|
# Global Setting
# ####
#  Case Sensitivity
#    If case_sensitive is set to false, the generated sql values will be lowercased (downcase)
#    By default: lotus.case_senstive = false
# ####
#  lotus.case_senstive = true

# Example Usage  
#  lotus.resource :job_offer do |u|
#    u.default_operators = {:full => "Matches"}
#    u.add_criterion :emplid, :operators => {:like => "Contains"}, :display => "Employee ID"
#    u.add_criterion :requisition_nbr, :operators => {:equal => "Is", :gt => "Greater Than"}, :display => "Req #"
#    u.add_criterion :active, :operators => {:equal => "Is"}, :type => :boolean
#    u.add_criterion :user_group, :operators => {:equal => "Is"}, :type => :select, :options => {:admin => "Admin", :editor => "Editor", :peasant => "Regular User"}
#  end

end
