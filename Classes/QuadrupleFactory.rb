require_relative 'SemanticCube'
require_relative 'Quadruple'
require_relative 'Program'

#######################
# Description: This class has the objective to create quadruples and solve neuralgic points code,
# it handles many issues and verifies semantic considerations with the SemanticCube class. It also
# communicates with the class program to see in which context to look. To start the quadruple factory,
# the class needs to know about the class progrma.
# Parameters: (program, type:Program)
# Return value: N/A
# Error handling: It handles many errors including all semantic considerations.
#######################
class QuadrupleFactory
  attr_accessor :param_index

  #######################
  # Description: Initializes QuadrupleFactory
  # Parameters: (program, type:Program)
  # Return value: N/A
  # Error handling: N/A
  #######################
  def initialize(program)
    @program = program
    @operators_stack = []
    @ids_stack = []
    @types_stack = []
    @memory_stack = []
    @jumps_stack = []
    @dim_stack = []
    @temp_counter = 1
    @sem_cube = SemanticCube.new()
    @param_index = 0
    @turn_off_if_dim = false
  end

  #######################
  # Description: Create a goto quadruple for the jump to the main program
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def goto_program()
    quad = Quadruple.new('GOTO', nil, nil, nil)
    @program.add_quadruples(quad)
    @jumps_stack.push(@program.counter)
    @program.counter += 1
  end

  #######################
  # Description: Adds id or value to the id_stack depending on the parameter
  # received
  # Parameters: (id, type:String), (value, type:String)
  # Return value: N/A
  # Error handling: Returns an error if it's trying to access a variable that
  # hasn't been declared
  #######################
  def add_id(id, value)
    if id != nil
        variable = get_variable(id)
        if variable.is_dim
          # flag to check if variable has brackets
          @turn_off_if_dim = true
        end
        if find_variable(id)
          variable = get_variable(id)
          @ids_stack.push(variable.name)
          @types_stack.push(variable.type)
          @memory_stack.push(variable.memory_dir)
        else
          puts "ERROR: #{id} is not declared."
          exit
        end
    elsif value != nil
      variable_type = match_value(value)
      variable_value = extract_value(value)
      @ids_stack.push("%#{variable_value}")
      @memory_stack.push("%#{variable_value}")
      @types_stack.push(variable_type)
    end
  end

  #######################
  # Description: Adds false bottom to the operators stack to prioritize
  # opertations.
  # Parameters: (parentesis, type:Char)
  # Return value: N/A
  # Error handling: N/A
  #######################
  def add_false_bottom(parentesis)
    @operators_stack.push(parentesis)
  end

  #######################
  # Description: Removes false bottom from the operators stack to signal
  # that the prioritized operation is done.
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def remove_false_bottom()
    @operators_stack.pop()
  end

  #######################
  # Description: Checks if a variable exists in the current and past context
  # Parameters: (id, type:String)
  # Return value: Boolean
  # Error handling: N/A
  #######################
  def find_variable(id)
    current_context = @program.current_context
    past_context = @program.past_context

    if current_context.variables_directory.variable_exists?(id)
      true
    elsif past_context.variables_directory.variable_exists?(id)
      true
    else
      false
    end
  end

  #######################
  # Description: Checks if a variable exists in the current and past context
  # Parameters: (id, type:String)
  # Return value: Variable
  # Error handling: Throws an error if the variable isn't declared.
  #######################
  def get_variable(id)
    current_context = @program.current_context
    past_context = @program.past_context

    if current_context.variables_directory.variable_exists?(id)
      current_context.variables_directory.get_variable(id)
    elsif past_context.variables_directory.variable_exists?(id)
      past_context.variables_directory.get_variable(id)
    else
      puts "ERROR: #{id} is not declared."
      exit
    end
  end

  #######################
  # Description: Adds an operation to the operators stack
  # Parameters: (operator, value:Char)
  # Return value: N/A
  # Error handling: N/A
  #######################
  def add_operator(operator)
    @operators_stack.push(operator)
  end

  #######################
  # Description: Checks if a term operation is pending
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def is_term_pending()
    if @operators_stack.last() == '*' || @operators_stack.last() == '/'
      generate_quad()
    end
  end

  #######################
  # Description: Checks if an exp operation is pending
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def is_exp_pending()
    if @operators_stack.last() == '+' || @operators_stack.last() == '-'
      generate_quad()
    end
  end

  #######################
  # Description: Checks if an expression operation is pending
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def is_expression_pending()
    if @operators_stack.last() == '>' || @operators_stack.last() == '<' || @operators_stack.last() == '==' ||
       @operators_stack.last() == '==' || @operators_stack.last() == '<>' || @operators_stack.last() == '>=' ||
       @operators_stack.last() == '<='
      generate_quad()
    end
  end

  #######################
  # Description: Checks if a super expression operation is pending
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def is_super_expression_pending()
    if @operators_stack.last() == 'and' || @operators_stack.last() == 'or'
      generate_quad()
    end
  end

  #######################
  # Description: Generates a read quadruple
  # Parameters: (id, type: String)
  # Return value: N/A
  # Error handling: N/A
  #######################
  def read(id)
    var_type = get_variable(id).type
    quad = Quadruple.new('read', "%", @memory_stack.last(), var_type)
    @program.add_quadruples(quad)
    @program.counter += 1
  end

  #######################
  # Description: Generates an assignment quadruple
  # Parameters: (id, type: String)
  # Return value: N/A
  # Error handling: N/A
  #######################
  def assgn_read()
    @ids_stack.pop()
    id = @memory_stack.pop()
    @types_stack.pop()
    op = @operators_stack.pop()
    quad = Quadruple.new(op, id, nil, id)
    @program.add_quadruples(quad)
    @program.counter += 1
  end

  #######################
  # Description: Generates a print quadruple
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def write()
    @ids_stack.pop()
    temp = @memory_stack.pop()
    type = @types_stack.pop()
    quad = Quadruple.new('print', temp, nil, nil)
    @program.add_quadruples(quad)
    @program.counter += 1
  end

  #######################
  # Description: Generates a gotof quadruple for a subrutine
  # Parameters: N/A
  # Return value: N/A
  # Error handling: Throws an error if the result isn't Bool.
  #######################
  def gotof()
    type = @types_stack.pop()
    if type == "Bool"
      @ids_stack.pop()
      result = @memory_stack.pop()

      quad = Quadruple.new('GOTOF', result, nil, nil)
      @program.add_quadruples(quad)
      @jumps_stack.push(@program.counter)
      @program.counter += 1
    else
      puts "ERROR: type mismatched, expecting Bool got #{type}."
      exit
    end
  end

  #######################
  # Description: Fills the pending jump when it reaches the main program
  # declaration
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def fill_program_quad()
    position = @jumps_stack.pop()
    @program.quadruples[position].result = @program.counter
  end

  #######################
  # Description: Fills a pending jump
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def fill_quad()
    position = @jumps_stack.pop()
    @program.quadruples[position].result = @program.counter + 1
  end

  #######################
  # Description: Generates a goto quadruple for a subrutine
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def goto()
    quad = Quadruple.new('GOTO', nil, nil, nil)
    @program.add_quadruples(quad)
    fill_quad()
    @jumps_stack.push(@program.counter)
    @program.counter += 1
  end

  #######################
  # Description: Adds the quadruple number that has a pending jump to the jump
  # stack
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def add_jump()
    @jumps_stack.push(@program.counter)
  end

  #######################
  # Description: Generates a goto quadruple for a while
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def goto_while()
    fill_quad()
    position = @jumps_stack.pop()
    quad = Quadruple.new('GOTO', nil, nil, position)
    @program.add_quadruples(quad)
    @program.counter += 1
  end

  #######################
  # Description: Checks if a variable exists in all contexts
  # Parameters: (id, type:String)
  # Return value: N/A
  # Error handling: Throws an error if the variable wasn't found.
  #######################
  def variable_exists?(id)
    exists_in_current_context = @program.current_context.variables_directory.variables[id] != nil
    exists_in_past_context = @program.past_context.variables_directory.variables[id] != nil
    exists_in_main_context = @program.main_context.variables_directory.variables[id] != nil

    if exists_in_current_context == false && exists_in_main_context == false && exists_in_past_context == false
      puts "ERROR: undeclared variable #{id}."
      exit
    end
  end

  #######################
  # Description: Checks if a function exists in the past context
  # Parameters: (id, type:String)
  # Return value: N/A
  # Error handling: Throws an error if the function wasn't found.
  #######################
  def function_exists?(id)
    exists_in_past_context = @program.past_context.functions_directory.functions[id] != nil

    if exists_in_past_context == false
      puts "ERROR: undeclared function #{id}."
      exit
    end
  end

  #######################
  # Description: Checks if an object exists in the current and past context, if
  # it does, it checks that the method exists in its class context.
  # Parameters: (var_name, type:String), (func_name, type:String)
  # Return value: the context of the object's class
  # Error handling: Throws an error if the object or thw method wasn't found.
  #######################
  def method_exists?(var_name, func_name)
    exists_in_current_context = @program.current_context.variables_directory.variables[var_name] != nil
    exists_in_past_context = @program.past_context.variables_directory.variables[var_name] != nil

    if exists_in_current_context == true
      var_type = @program.current_context.variables_directory.variables[var_name].type
    elsif exists_in_past_context == true
      var_type = @program.past_context.variables_directory.variables[var_name].type
    else
      puts "ERROR: undeclared variable #{var_name}."
      exit
    end

    class_context = @program.main_context.classes_directory.classes[var_type].context
    exists_in_function_directory = class_context.functions_directory.functions[func_name] != nil

    if exists_in_function_directory == false
      puts "ERROR: undeclared method #{func_name} for object #{var_name}."
      exit
    end
    class_context
  end

  #######################
  # Description: Generates an era quadruple for a function call
  # Parameters: (func_name, type:String)
  # Return value: N/A
  # Error handling: N/A
  #######################
  def era(func_name)
    return_type = @program.past_context.functions_directory.functions[func_name].return_type
    @ids_stack.push(func_name)
    @memory_stack.push(func_name)
    @types_stack.push(return_type)
    quad = Quadruple.new('ERA', nil, nil, func_name)
    @program.add_quadruples(quad)
    @program.counter += 1
    @param_index = 0
  end

  #######################
  # Description: Generates an era quadruple for an objects method call
  # Parameters: (id, type:String), (method_name, type:String)
  # Return value: N/A
  # Error handling: N/A
  #######################
  def era_method(id, method_name)
    context = method_exists?(id, method_name)
    return_type = context.functions_directory.functions[method_name].return_type
    @ids_stack.push(method_name)
    @memory_stack.push(method_name)
    @types_stack.push(return_type)
    quad = Quadruple.new('ERA', id, nil, method_name)
    @program.add_quadruples(quad)
    @program.counter += 1
    @param_index = 0
  end

  #######################
  # Description: Generates a parameter quadruple for a function call
  # Parameters: (func_name, type:String)
  # Return value: N/A
  # Error handling: Throws an error if the value you are trying to pass doesn't match
  # the one declared in the function
  #######################
  def parameter(func_name)
    id = @ids_stack.pop()
    arg = @memory_stack.pop()
    arg_type = @types_stack.pop()
    if @program.past_context.functions_directory.functions[func_name].parameters[@param_index].type == arg_type
      quad = Quadruple.new('PARAM', arg, nil, "param#{param_index}")
      @program.add_quadruples(quad)
      @program.counter += 1
      @param_index += 1
    else
      puts "ERROR parameter #{param_index} of value #{id} is of type mismatched."
      exit
    end
  end

  #######################
  # Description: Verifies that the number of parameters you're trying to pass
  # matches the ones in the function declaration
  # Parameters: (func_name, type:String)
  # Return value: N/A
  # Error handling: Throws an error if the parameters count doesn't match.
  #######################
  def verify_func_param_count(func_name)
    func_params_count = @program.past_context.functions_directory.functions[func_name].parameters.count
    if func_params_count != @param_index
      puts "ERROR: wrong number of parameters (#{@param_index} for #{func_params_count}) in #{func_name} call."
      exit
    end
  end

  #######################
  # Description: Generates a gosub quadruple for a function call
  # Parameters: (func_name, type:String)
  # Return value: N/A
  # Error handling: N/A
  #######################
  def go_sub(func_name)
    quad_number = @program.past_context.functions_directory.functions[func_name].quad_number
    quad = Quadruple.new('GOSUB', func_name, quad_number, nil)
    @program.add_quadruples(quad)
    @program.counter += 1
  end

  #######################
  # Description: Generates a gosub quadruple for an object's method call
  # Parameters: (id, type:String), (method_name, type:String)
  # Return value: N/A
  # Error handling: N/A
  #######################
  def go_sub_method(id, method_name)
    context = method_exists?(id, method_name)
    quad_number = context.functions_directory.functions[method_name].quad_number
    quad = Quadruple.new('GOSUB', method_name, quad_number, nil)
    @program.add_quadruples(quad)
    @program.counter += 1
  end

  #######################
  # Description: Generates an assignment quadruple for return value from a
  # function, it saves the value with the function name as the key.
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def get_return_value()
    func_name = @ids_stack.pop()
    @memory_stack.pop()
    func_type = @types_stack.pop()
    @program.set_next_memory()
    temp = @program.memory_counter()
    quad = Quadruple.new('=', func_name, nil, temp)
    @ids_stack.push(temp)
    @memory_stack.push(temp)
    @types_stack.push(func_type)
    @program.quadruples.push(quad)
    @program.counter += 1
  end

  #######################
  # Description: Generates a return quadruple when a function finishes
  # Parameters: (func_name, type:String)
  # Return value: N/A
  # Error handling: Throws an error if the return type is different from the one
  # specified in the function declaration
  #######################
  def return(func_name)
    func_type = @program.past_context.functions_directory.functions[func_name].return_type
    @ids_stack.pop()
    temp = @memory_stack.pop()
    temp_type = @types_stack.pop()

    if func_type != temp_type
      puts "ERROR: expected return type of #{func_type}, got #{temp_type}."
      exit
    else
      quad = Quadruple.new('return', temp, nil, nil)
      @program.add_quadruples(quad)
      @program.counter += 1
    end
  end

  #######################
  # Description: Generates a endfunc quadruple when a function call finishes
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def end_function()
    quad = Quadruple.new('ENDFUNC', nil, nil, nil)
    @program.add_quadruples(quad)
    @program.counter += 1
  end

  #######################
  # Description: Generates a parameter quadruple for an object's method call
  # Parameters: (var_name, type:String), (func_name, type:String)
  # Return value: N/A
  # Error handling: Throws an error if the value you are trying to pass doesn't match
  # the one declared in the method
  #######################
  def method_parameter(var_name, func_name)
    id = @ids_stack.pop()
    arg = @memory_stack.pop()
    arg_type = @types_stack.pop()

    context = method_exists?(var_name, func_name)
    parameter = context.functions_directory.functions[func_name].parameters[@param_index]
    if parameter == nil
      puts "ERROR: parameter index out of bounds for #{func_name}."
      exit
    end
    if parameter.type == arg_type
      quad = Quadruple.new('PARAM', arg, nil, "param#{param_index}")
      @program.add_quadruples(quad)
      @program.counter += 1
      @param_index += 1
    else
      puts "ERROR parameter #{param_index} of value #{id} is of type mismatched."
      exit
    end
  end

  #######################
  # Description: Verifies that the number of parameters you're trying to pass
  # matches the ones in the object's method declaration
  # Parameters: (var_name, type:String), (func_name, type:String)
  # Return value: N/A
  # Error handling: Throws an error if the parameters count doesn't match.
  #######################
  def verify_method_param_count(var_name, func_name)
    context = method_exists?(var_name, func_name)
    method_params_count = context.functions_directory.functions[func_name].parameters.count
    if method_params_count != @param_index
      puts "ERROR: wrong number of parameters (#{@param_index} for #{method_params_count}) in #{func_name} call."
      exit
    end
  end

  #######################
  # Description: Generates an assignment quadruple
  # Parameters: N/A
  # Return value: N/A
  # Error handling: Throws an error if the type expected and received doesn't match
  #######################
  def assgn_quad()
    @ids_stack.pop()
    result = @memory_stack.pop()

    result_type = @types_stack.pop()
    @ids_stack.pop()
    id = @memory_stack.pop()
    id_type = @types_stack.pop()
    op = @operators_stack.pop()

    if result_type == id_type
      quad = Quadruple.new(op, result, nil, id)
      @program.add_quadruples(quad)
      @program.counter += 1
    else
      puts "ERROR: type mismatched, received #{id_type} and #{result_type}."
      exit
    end
  end

  #######################
  # Description: Checks if limits are present in a dimensional variable call
  # Parameters: (id, type:String)
  # Return value: N/A
  # Error handling: Throws an error if the variable is dimensional and the brackets
  # weren't present in the call
  #######################
  def check_dim(id)
    if @turn_off_if_dim
      puts "ERROR: Missing limits for #{id}."
      exit
    end
  end

  #######################
  # Description: Checks if a variable is dimensional, if it is, it adds it to the
  # dim stack
  # Parameters: N/A
  # Return value: N/A
  # Error handling: Throws an error if you try to access a variables that isn't
  # dimensional as if it is.
  #######################
  def is_dim()
    # Turn off flag because the brackets were present
    @turn_off_if_dim = false

    id = @ids_stack.pop()
    @memory_stack.pop()
    @types_stack.pop()

    if !get_variable(id).is_dim
      puts "ERROR: #{id} is not a dimensional variable."
      exit
    end
    dim = 0
    @dim_stack.push([id, dim])
    add_false_bottom('(')
  end

  #######################
  # Description: Generates quadruples to access a dimensional variable
  # Parameters: N/A
  # Return value: N/A
  # Error handling: Throws an error if you try to access a dimensional variable
  # with the wrong dimensions
  #######################
  def generate_limit_quad()
    id = @ids_stack.last()
    memory_id = @memory_stack.last()
    dim = @dim_stack.last()[1]
    dim_id = @dim_stack.last()[0]
    var_dim_structures = get_variable(dim_id).dim_structures
    if var_dim_structures[dim] == nil
      puts "ERROR: wrong dimension size for #{dim_id}."
      exit
    end
    limit = var_dim_structures[dim].limit
    m = var_dim_structures[dim].m
    quad = Quadruple.new("VERIFICAR", memory_id, 0, limit)
    @program.add_quadruples(quad)
    @program.counter += 1

    if var_dim_structures[dim + 1] != nil
      @ids_stack.pop()
      aux = @memory_stack.pop()
      @types_stack.pop()
      @program.set_next_memory()
      temp = @program.memory_counter
      quad = Quadruple.new('*', aux, "%#{m}", temp)
      @program.add_quadruples(quad)
      @program.counter += 1
      @ids_stack.push(temp)
      @memory_stack.push(temp)
      @types_stack.push('Integer')
    elsif dim > 0
      @ids_stack.pop()
      aux2 = @memory_stack.pop()
      @types_stack.pop()

      @ids_stack.pop()
      aux1 = @memory_stack.pop()
      @types_stack.pop()

      @program.set_next_memory()
      temp = @program.memory_counter

      quad = Quadruple.new('+', aux1, aux2, temp)
      @program.add_quadruples(quad)
      @program.counter += 1
      @ids_stack.push(temp)
      @memory_stack.push(temp)
      @types_stack.push('Integer')
    end
  end

  #######################
  # Description: Updates a dimensional variable dimension if it's a matrix
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def update_dim()
    @dim_stack.last()[1] += 1
  end

  #######################
  # Description: Verifies that you are accessing a dimensional variable with the
  # right dimensions
  # Parameters: N/A
  # Return value: N/A
  # Error handling: Throws an error if you give other dimensions than the ones
  # declared
  #######################
  def verify_dim_access()
    curret_dim = @dim_stack.last()
    dim = curret_dim[1]
    id = curret_dim[0]
    dim_structures_count = get_variable(id).dim_structures.count

    if dim + 1 != dim_structures_count
      puts "ERROR: received #{dim + 1} expected #{dim_structures_count} limits."
      exit
    end
  end

  #######################
  # Description: Generates a quadruple to access the value in a stored virtual
  # memory direction
  # Parameters: N/A
  # Return value: N/A
  # Error handling: N/A
  #######################
  def generate_dim_quads()
    verify_dim_access()
    @ids_stack.pop()
    aux = @memory_stack.pop()
    @types_stack.pop()
    dim_id = @dim_stack.last()[0]
    dim_dir = get_variable(dim_id).memory_dir
    @program.set_next_memory()
    temp = @program.memory_counter
    quad = Quadruple.new('+', aux, "%#{dim_dir}", temp)
    @program.add_quadruples(quad)
    @program.counter += 1
    @ids_stack.push("(#{temp})")
    @memory_stack.push("(#{temp})")
    id_type = get_variable(dim_id).type
    @types_stack.push(id_type)
    remove_false_bottom()
    @dim_stack.pop()
  end

private
  #######################
  # Description: Generates quadruples for operations (arithmetic and logical)
  # Parameters: N/A
  # Return value: N/A
  # Error handling: Throws an error if you try to do an operation with invalid
  # variable types
  #######################
  def generate_quad()
    operator = @operators_stack.pop()
    operator_type = @sem_cube.convert[operator]
    @ids_stack.pop()
    right_side = @memory_stack.pop()
    right_side_type = @sem_cube.convert[@types_stack.pop()]
    @ids_stack.pop()
    left_side = @memory_stack.pop()
    left_side_type = @sem_cube.convert[@types_stack.pop()]
    type_res = @sem_cube.semantic_cube[[left_side_type, right_side_type, operator_type]]
    if type_res != nil
      @program.set_next_memory()
      temp = @program.memory_counter

      quad = Quadruple.new(operator, left_side, right_side, temp)
      @program.add_quadruples(quad)

      @ids_stack.push(temp)
      @memory_stack.push(temp)

      @types_stack.push(@sem_cube.invert[type_res])
      current_context = @program.current_context
      current_context.variables_directory.register(temp, @sem_cube.invert[type_res], @program.memory_counter)
      @program.counter += 1
    else
      puts "ERROR: variable type mismatched, received: #{left_side} and #{right_side}."
      exit
    end
  end

  #######################
  # Description: Given a string, it returns a parsed value
  # Parameters: (value, type: String)
  # Return value: parsed value
  # Error handling: N/A
  #######################
  def extract_value(value)
    if value == "true"
      true
    elsif value == "false"
      false
    elsif value.include? '.'
      value.to_f
    elsif value.scan(/\D/).empty?
      value.to_i
    else
      value
    end
  end

  #######################
  # Description: returns the class of a variable
  # Parameters: (value, type: String)
  # Return value: String
  # Error handling: N/A
  #######################
  def match_value(value)
    value = value.to_s
    if value == "true" || value == "false"
      "Bool"
    elsif value.include? '.'
      "Float"
    elsif value.scan(/\D/).empty?
      "Integer"
    else
      "String"
    end
  end
end
