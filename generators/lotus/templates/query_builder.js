var QueryBuilder = Class.create({
  /*
     MOVE THIS DOCUMENTATION
        -- A condition can respond: 
           isTupleSet - yes
           isConditionsSet - no
              - or -
           isTupleSet - no
           isConditionsSet - yes
              - OR -
           isTupleSet - no
           isConditionsSet - no         .. This is a blank one 
     QueryBuilder is built under the assumption of facilitating only one condition of conditions not nested conditions.
  */

 initialize: function(options) {
   options = $H(options);

   if(!options.get("criteria")) {
     alert("ERROR: criteria was not set");
   }
   this.criteria = options.get("criteria");

   if(!options.get("root")) {
     alert("ERROR: root was not set.");
   }
   this.root = options.get("root");


   if(!options.get("condition")) {
     this.root_condition = new Condition({conjunction: "AND", col_name: this.criteria.first().name });
   }
   else {
     this.root_condition = options.get("condition");
   }

   this.reload();
  },

  toHTML: function() {
    var root_node = Builder.node("div", {className: "root conditions"}),
              add = Builder.node("a", {className: "addAction", href: "#", onclick: "return false;"}, "Add");

    Event.observe(add, "click", this.addCondition.bindAsEventListener(this));
   
    root_node.appendChild(add);
    root_node.appendChild(this.recurHTML(this.root_condition));

    return root_node;
  },

  reload: function() {
    this.root.update(this.toHTML());
  },

  recurHTML: function(condition) {
    if(!condition.isConditionsSet()) {
      return this.buildTupleForm(condition)
    }
    else {
      var c_root = this.buildConditionForm(condition);
      condition.conditions.each(function(i_condition){
         c_root.down(".conditions").appendChild(this.recurHTML(i_condition));
      }, this);
      return c_root;
    }
  },

  addCondition: function(event) {
    this.root_condition.addCondition(new Condition({col_name: this.criteria.first().name}));
    this.reload();
  },

  removeCondition: function(event) {
    var ele = Event.element(event);
    ele = ele.up(".tuple");  // Ensure we have the div, child to conditions
   
    var index = ele.previousSiblings().size(); 

    this.root_condition.removeCondition(index);  // Would not be able to assume root_condition if nested.
    this.reload();
  },
  
  watchCondition: function(event) {
    var ele = Event.element(event);

    var change_operators = false;
    var change_values = false;
    if( ele.hasClassName("criteriaSelect") ) {
      change_operators = true;
      change_values = true;
    }
  
    ele = ele.up(".tuple");
 
    var index = ele.previousSiblings().size();

    var condition = this.root_condition;
    if(this.root_condition.isConditionsSet()) {
      condition = this.root_condition.conditions[index];
    }

    if(change_operators) {
      condition.col_name = ele.down(".criteriaSelect").value;
      ele.down(".operatorSelect").replace(this.buildOperatorSelect(condition));
    }  
    
    if(change_values) {
      // re-add listener to value field
      value_field = ele.down(".valueField")
      condition.col_value = value_field.value;
      value_field.replace(this.buildValueField(condition));
      //get new object
      new_value_field = ele.down(".valueField")
      Event.observe(new_value_field, "change", this.watchCondition.bindAsEventListener(this));
    }

    condition.setTuple($H({col_name: ele.down(".criteriaSelect").value, col_operator: ele.down(".operatorSelect").value, col_value: ele.down(".valueField").value}));
  }, 

  buildTupleForm: function(condition) {
    var tuple = Builder.node("div", { className: "tuple" }),
          rem = Builder.node("a", { className: "removeAction", href: "#", onclick: "return false;" }, "Remove"),
          sel = this.buildCriteriaSelect(condition),
           op = this.buildOperatorSelect(condition),
          val = this.buildValueField(condition);
          
    tuple.appendChild(sel);
    tuple.appendChild(op);
    tuple.appendChild(val);
    tuple.appendChild(rem);

    Event.observe(rem, "click", this.removeCondition.bindAsEventListener(this));
    Event.observe(sel, "change", this.watchCondition.bindAsEventListener(this));
    Event.observe(op, "change", this.watchCondition.bindAsEventListener(this));
    Event.observe(val, "change", this.watchCondition.bindAsEventListener(this));
    
    return tuple;
  },

  buildCriteriaSelect: function(condition) {
    var sel = Builder.node("select", { className: "criteriaSelect" } );
    var selected = 0;
    this.criteria.each(function(criterion, index){
      criterion = $H(criterion);
      var column_option = Builder.node("option", {value: criterion.get("name")}, criterion.get("display")) ;

      if(condition.col_name == criterion.get("name")) {
        selected = index;
      }

      sel.appendChild( column_option );
    }, this);
 
    sel.selectedIndex = selected;

    return sel;
  },
  
  buildOperatorSelect: function(condition) {
    var op = Builder.node("select", { className: "operatorSelect" } );
    var selected = 0;
    var crit = this.getCriteria(condition.col_name);
    if(crit.operators) {
      var operators = $H(crit.operators);
      operators.each(function(operator, index){
        var operator_option = Builder.node("option", {value: operator[0]}, operator[1]) ;
  
         if(condition.col_operator == operator[0]) {
          selected = index;
        }

        op.appendChild( operator_option );
      }, this);     
    }

    op.selectedIndex = selected;    

    return op;
  },
  
  buildBooleanSelectValueField: function(condition) {
    opts = [];
    if(condition.col_value) {
      selected_index = 0;
      if(condition.col_value == "0" || condition.col_value == 0) {
        selected_index = 1;
      }
      
      opts[0] = Builder.node("option", {value: "1"}, "Yes");
      opts[1] = Builder.node("option", {value: "0"}, "No");
      select = Builder.node("select", {className: "valueField"}, opts);
      select.selectedIndex = selected_index;
      return select;
    } else {
      opts[0] = Builder.node("option", {value: "1"}, "Yes");
      opts[1] = Builder.node("option", {value: "0"}, "No");
      return Builder.node("select", {className: "valueField"}, opts);
    }
  },
  
  buildTextValueField: function(condition) {
    if(condition.col_value) {
      return Builder.node("input", { className: "valueField" , type: "text" ,  value: condition.col_value} );
    }
    else {
      return Builder.node("input", { className: "valueField" , type: "text" } );
    }
  },
  
  buildValueField: function(condition) {
    criteria = this.getCriteria(condition.col_name);
    if(criteria.type == 'boolean') {      
      return this.buildBooleanSelectValueField(condition);
    }    
    else {
      return this.buildTextValueField(condition);
    }
  },

  buildConditionForm: function(condition) {
    var cond = Builder.node("div", {className: "condition"}),
         con = this.buildConjunctionSelect(condition),
          cs = Builder.node("div", {className: "conditions"});
  
     cond.appendChild(con);
     cond.appendChild(cs);

     Event.observe(con, "change", this.watchConjunction.bindAsEventListener(this));
    
     return cond;
  },

  buildConjunctionSelect: function(condition) {
    var c_sel = Builder.node("select", {className: "conjunctionSelect"});
    var selected = 0;
    
    (new Array("AND", "OR")).each(function(conjunction, index){
      var conjunction_option = Builder.node("option", {value: conjunction}, conjunction) ;

      if(condition.conjunction == conjunction) {
        selected = index;        
      }

      c_sel.appendChild(conjunction_option);
    }, this);

    c_sel.selectedIndex = selected;
    return c_sel;
  },
  
  watchConjunction: function(event) {
    this.root_condition.conjunction = event.target.value;
  },

  getCriteria: function(criterion_name) {
    var result = {};
    this.criteria.each( function(criterion) {
      if(criterion.name == criterion_name) {
        result = criterion;
        return result; // Returning from .each
      }
    }, this);
    return result;
  },
  injectRootCondition: function(target) {

    var sub_fin = document.createElement('input');
    sub_fin.type = "hidden";
    sub_fin.name = "conditions";
    sub_fin.value = Object.toJSON(this.root_condition);

    this.root.appendChild(sub_fin);
  }
});

/*

<?xml version="1.0" encoding="UTF-8"?>
<condition conjunction="OR">
  <conditions>
    <condition conjunction="AND">
      <col_name>user_name</col_name>
      <col_operator>LIKE</col_operator>
      <col_value>verm0032</col_value>
    </condition>
    <condition>
      <col_name>user_name</col_name>
      <col_operator>LIKE</col_operator>
      <col_value>MyString</col_value>
    </condition>
    <condition>
       <col_name>id_col</col_name>
       <col_operator>=</col_operator>
       <col_value>1</col_value>
    </condition>
  </conditions>
</condition>


<div class="condition">
  <div class="conjunction">   # -- Hidden Unless conditions exist.
  </div>
  <div class="tuple">   # -- Either tuple or conditions would exist. Not both.
  </div>
  <div class="conditions">
  </div>
</div>

Javascript object:
Condition  
  implements:
    ## Renders ##
      -to_xml
      -to_json
    ## Getter/Setters ##
      -set_conjunction
      -set_tuple            // Not allowed if conditions set.
      -get_conditions       
      -add_condition        // Adding a condition to a tuple would: 1) Remove the tuple 2) Set the tuple as a child condition 3) Add the desired condition
      -remove_condition
    ## load/save ##
      -load_from_xml   **
      -load_from_json
      -save_to_xml     **
      -save_to_json

FormCondition
  has_one: Condition
  implements:
    ## Renders ##
      -to_html
    ## Getter/Setters ##
      -build_tuple_form
      -build_condition_form
      -add_condition
      -remove_condition
*/


/*
Demonstration:

c = new Condition($H({col_name: "test", col_operator: "=", col_value: "something"}));

c.isTupleSet() => true
c.isConditionsSet() => false

c.addCondition(new Condition($H({col_name: "sub_test", col_operator: "=", col_value: "sub_something"})));

c.isTupleSet() =>  false
c.isConditionsSet() => true


c.removeCondition(0);

c.isTupleSet() => true
c.isConditionsSet() => false

This structure supports nested conditions.
The accompanying QueryBuilder is built under the assumption of just one nested condition.

*/

var Condition = Class.create({

  /* options ==> {col_name: ... , col_operator: ... , col_value: ... , conjunction: ... , conditions: ...} */
  initialize: function(options) {
 
    options = $H(options);
  
    this.col_name = "";
    this.col_operator = "";
    this.col_value = "";
    this.conjunction = "AND";
    this.col_type = "text";

    if(options.get("col_name")) 
      this.col_name = options.get("col_name");
    if(options.get("col_operator"))
      this.col_operator = options.get("col_operator");
    if(options.get("col_value")!=="") //otherwise a value of "0" will fail the check
      this.col_value = options.get("col_value");
 
    if(options.get("conjunction"))
      this.conjunction = options.get("conjunction");
  
    this.conditions = new Array();

    if(options.get("conditions") && (options.get("conditions") instanceof Array)) {
      options.get("conditions").each(function(condition) { 
        this.conditions.push(new Condition(condition));
        }, this);
      }
  },
  
  setConjunction: function(conjunction) {
    this.conjunction = conjunction;
  },
 
  setTuple: function(options) {
    if(this.isConditionsSet()) {
      alert("ERROR: cannot set tuple when the condition contains conditions.");
    }
    else {
      this.col_name = options.get("col_name"); 
      this.col_operator = options.get("col_operator");
      this.col_value = options.get("col_value");
    }
  },

  isTupleSet: function() {
    if(this.col_name.empty() && this.col_operator.empty() && this.col_value.empty())
      return false
    return true 
  },
  
  isConditionsSet: function() {
    if(!this.conditions || this.conditions.size() == 0)
      return false
    return true
  },

  addCondition: function(condition) {
    if(this.isTupleSet()) {
      // Temporarily store tuple.
      temp = new Hash();
      temp.set("col_name", this.col_name);
      temp.set("col_operator", this.col_operator);
      temp.set("col_value", this.col_value);
      temp.set("conjuction", this.conjunction);
      tempC = new Condition(temp);
   
      // Remove this.tuple
      this.setTuple($H({col_name: "", col_operator: "", col_value: ""}));
      
      // Add the temporary tuple as a child condition.
      this.addCondition(tempC);
      this.addCondition(condition);
    }
    else {
      this.conditions.push( condition );      
    }
  },

  removeCondition: function(index) {
    removed = false;
    if( this.conditions.size() > 1 ) {
      if( index < this.conditions.size() && index >= 0 ) {
        this.conditions.splice(index, 1);
        removed = true;
      }
      else {
        alert("ERROR: index out of bounds.");
        return false;
      }
      
    }

    if( this.conditions.size() == 1 ) {   // revert to tuple
      temp = new Hash();
      temp.set("col_name", this.conditions.first().col_name);
      temp.set("col_operator", this.conditions.first().col_operator);
      temp.set("col_value", this.conditions.first().col_value);
     
      this.conditions.splice(0, 1);
      
      this.setTuple(temp);
    }

    return removed;
  }
});
