require 'fy/codegen'
Type   = require('type')
mod_ast= require('./ast')
module = @

translate_type = (type)->
  if type.is_user_defined
    return type.main
  switch type.main
    when 'bool'
      'bool'
    when 'uint'
      'u64'
    when 'int'
      'i64'
    when 'address'
      'String'
    when 'map'
      "HashMap<#{translate_type type.nest_list[0]},#{translate_type type.nest_list[1]}>"
    else
      ### !pragma coverage-skip-block ###
      pp type
      throw new Error("unknown solidity type '#{type}'")
    
@bin_op_name_map =
  ADD : '+'
  SUB : '-'
  MUL : '*'
  DIV : '/'
  MOD : '%'
  
  EQ : '=='
  NE : '!='
  GT : '>'
  LT : '<'
  GTE: '>='
  LTE: '<='
  
  
  BIT_AND : '&'
  BIT_OR  : '|'
  BIT_XOR : '^'
  
  BOOL_AND: '&&'
  BOOL_OR : '||'

@bin_op_name_cb_map =
  ASSIGN  : (a, b)-> "#{a} = #{b}"
  ASS_ADD : (a, b)-> "#{a} += #{b}"
  ASS_SUB : (a, b)-> "#{a} -= #{b}"
  ASS_MUL : (a, b)-> "#{a} *= #{b}"
  ASS_DIV : (a, b)-> "#{a} /= #{b}"
  
  # NOT VFERIFIED
  INDEX_ACCESS : (a, b, ctx, ast)->
    "#{a}.getSome(#{b})"

@un_op_name_cb_map =
  MINUS   : (a)->"-(#{a})"
  BOOL_NOT: (a)->"!(#{a})"
  BIT_NOT : (a)->"~(#{a})"
  BRACKET : (a)->"(#{a})"
  
  # PRE_INCR: (a)->"++#{a}"
  # POST_INCR: (a)->"#{a}++"
  # PRE_DECR: (a)->"--#{a}"
  # POST_DECR: (a)->"#{a}--"
  
  PRE_INCR : (a)->"#{a}+=1"
  POST_INCR: (a)->
    p "NOTE please look at #{a}+=1 it was translated from postfix increment"
    "#{a}+=1"
  PRE_DECR : (a)->"#{a}-=1"
  POST_DECR: (a)->
    p "NOTE please look at #{a}-=1 it was translated from postfix decrement"
    "#{a}-=1"
  
  # NOTE unary plus is now disallowed
  # PLUS    : (a)->"+(#{a})"

class @Gen_context
  parent : null
  is_contract : false
  is_struct   : false
  var_hash  : {}
  continue_append : ''
  constructor : ()->
    @var_hash = {}
  
  mk_nest : ()->
    t = new module.Gen_context
    t.parent = @
    t
  
  is_contract_var : (name)->
    return true if @is_contract and @var_hash[name]
    if @parent
      return @parent.is_contract_var name
    return false

@boilerplate = """
#![feature(const_vec_new)]
use borsh::{BorshDeserialize, BorshSerialize};
use near_bindgen::{env, near_bindgen};
use serde_json::json;

#[global_allocator]
static ALLOC: wee_alloc::WeeAlloc = wee_alloc::WeeAlloc::INIT;
"""
@gen = (ast, opt = {})->
  ctx = new module.Gen_context
  ret = module._gen ast, opt, ctx
  
  """
  #{module.boilerplate}
  
  #{ret}
  """#"


@_gen = gen = (ast, opt, ctx)->
  switch ast.constructor.name
    # ###################################################################################################
    #    expr
    # ###################################################################################################
    when "Var"
      {name} = ast
      if ctx.is_contract_var name
        return "self.#{name}"
      name
    
    when "Const"
      switch ast.type.main
        when 'string'
          JSON.stringify ast.val
        else
          ast.val
    
    when 'Bin_op'
      ctx_lvalue = ctx.mk_nest()
      _a = gen ast.a, opt, ctx_lvalue
      _b = gen ast.b, opt, ctx
      if op = module.bin_op_name_map[ast.op]
        "(#{_a} #{op} #{_b})"
      else if cb = module.bin_op_name_cb_map[ast.op]
        cb(_a, _b, ctx, ast)
      else
        ### !pragma coverage-skip-block ###
        throw new Error "Unknown/unimplemented bin_op #{ast.op}"
    
    when "Un_op"
      if cb = module.un_op_name_cb_map[ast.op]
        cb gen(ast.a, opt, ctx), ctx
      else
        ### !pragma coverage-skip-block ###
        throw new Error "Unknown/unimplemented un_op #{ast.op}"
    
    when "Field_access"
      t = gen ast.t, opt, ctx
      ret = "#{t}.#{ast.name}"
      ret
    
    when "Fn_call"
      fn = gen ast.fn, opt, ctx
      arg_list = []
      for v in ast.arg_list
        arg_list.push gen v, opt, ctx
      
      "#{fn}(#{arg_list.join ', '})"
    
    # ###################################################################################################
    #    stmt
    # ###################################################################################################
    when "Scope"
      jl = []
      for v in ast.list
        val = gen v, opt, ctx
        val += ';' unless val[val.length-1] == ';'
        jl.push val
      join_list jl, ''
    
    when "Var_decl"
      ctx.var_hash[ast.name] = ast.type
      type = translate_type ast.type
      
      if ctx.is_struct
        pre = "#{ast.name}:#{type}"
      else
        pre = "let mut #{ast.name}:#{type}"
      
      if ast.assign_value
        val = gen ast.assign_value, opt, ctx
        "#{pre} = #{val}"
      else
        pre
    
    when "Ret_multi"
      if ast.t_list.length > 1
        throw new Error "not implemented ast.t_list.length > 1"
      
      jl = []
      for v in ast.t_list
        jl.push gen v, opt, ctx
      """
      return #{jl.join ', '}
      """
    
    when "If"
      cond = gen ast.cond, opt, ctx
      t    = gen ast.t, opt, ctx
      f    = gen ast.f, opt, ctx
      """
      if #{cond} {
        #{make_tab t, '  '}
      } else {
        #{make_tab f, '  '}
      }
      """
    
    when "While"
      cond = gen ast.cond, opt, ctx
      scope  = gen ast.scope, opt, ctx
      """
      while #{cond} {
        #{make_tab scope, '  '}
      } 
      """
    
    when "For_3pos"
      init  = if ast.init then gen ast.init, opt, ctx else ""
      cond  = gen ast.cond, opt, ctx
      incr  = if ast.incr then gen ast.incr, opt, ctx else ""
      ctx = ctx.mk_nest()
      ctx.continue_append = incr
      scope = gen ast.scope, opt, ctx
      
      aux_init = ""
      aux_init = "#{init};\n" if init
      
      aux_incr = ""
      aux_incr = "\n  #{incr};" if incr
      
      
      """
      #{aux_init}while #{cond} {
        #{make_tab scope, '  '}#{aux_incr}
      }
      """
    
    when "Continue"
      if ctx.continue_append
        """
        #{ctx.continue_append};
        continue
        """
      else
        "continue"
    
    when "Break"
      "break"
    
    when "Class_decl"
      ctx = ctx.mk_nest()
      if ast.is_struct
        ctx.is_struct = true
      else
        ctx.is_contract = true
      
      var_decl_jl = []
      fn_decl_jl = []
      for v in ast.scope.list
        switch v.constructor.name
          when 'Var_decl'
            res = gen v, opt, ctx
            res += ";"
            var_decl_jl.push res
          when 'Fn_decl_multiret'
            fn_decl_jl.push gen v, opt, ctx
          else
            p v
            throw new Error("unknown v.constructor.name = #{v.constructor.name}")
      
      if ast.is_struct
        """
        #[near_bindgen]
        #[derive(Default, BorshDeserialize, BorshSerialize)]
        pub struct #{ast.name} {
          #{join_list var_decl_jl, "  "}
        }
        
        """
      else
        """
        #[near_bindgen]
        #[derive(Default, BorshDeserialize, BorshSerialize)]
        pub struct #{ast.name} {
          #{join_list var_decl_jl, '  '}
        }
        #[near_bindgen]
        impl #{ast.name} {
          #{join_list fn_decl_jl, "  "}
        }
        
        """
    
    when "Fn_decl_multiret"
      ctx_orig = ctx
      ctx = ctx.mk_nest()
      arg_jl = []
      arg_jl.push "&mut self"
      for v,idx in ast.arg_name_list
        arg_jl.push "#{v}:#{translate_type ast.type_i.nest_list[idx]}"
      body = gen ast.scope, opt, ctx
      
      if ast.type_o.nest_list.length
        o_type = translate_type ast.type_o.nest_list[0]
      else
        o_type = "void"
      
      aux_export = ""
      if ast.visibility == 'public'
        aux_export = "pub "
      
      """
      #{aux_export}fn #{ast.name}(#{arg_jl.join ', '}):#{o_type} {
        #{make_tab body, '  '}
      }
      """
      
    else
      if opt.next_gen?
        return opt.next_gen ast, opt, ctx
      ### !pragma coverage-skip-block ###
      perr ast
      throw new Error "unknown ast.constructor.name=#{ast.constructor.name}"