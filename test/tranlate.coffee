assert = require 'assert'
ast_gen             = require('../src/ast_gen')
solidity_to_ast4gen = require('../src/solidity_to_ast4gen')
type_inference      = require('../src/type_inference')
translate           = require('../src/translate')


make_test = (text_i, text_o_expected)->
  text_o_expected = """
  #{translate.boilerplate}
  
  #{text_o_expected}
  """
  solidity_ast = ast_gen text_i, silent:true
  ast = solidity_to_ast4gen solidity_ast
  ast = type_inference.gen ast
  text_o_real = translate.gen ast
  text_o_expected = text_o_expected.trim()
  text_o_real     = text_o_real.trim()
  assert.strictEqual text_o_expected, text_o_real


describe 'translate section', ()->
  it 'empty', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Summator {
      uint public value;
      
      function test() public {
        value = 1;
      }
    }
    """
    text_o = """
    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct Summator {
      let mut value:u64;
    }
    #[near_bindgen]
    impl Summator {
      pub fn test(&mut self):void {
        self.value = 1;
      }
    }
    ;
    """#"
    make_test text_i, text_o
  
  it 'if', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Ifer {
      uint public value;
      
      function ifer() public returns (uint yourMom) {
        uint x = 5;
        uint ret = 0;
        if (x == 5) {
          ret = value + x;
        }
        else  {
          ret = 0;
        }
        return ret;
      }
    }
    """
    text_o = """
    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct Ifer {
      let mut value:u64;
    }
    #[near_bindgen]
    impl Ifer {
      pub fn ifer(&mut self):u64 {
        let mut x:u64 = 5;
        let mut ret:u64 = 0;
        if (x == 5) {
          ret = (self.value + x);
        } else {
          ret = 0;
        };
        return ret;
      }
    }
    ;
    """#"
    make_test text_i, text_o
  
  # TODO require
  
  it 'bool ops', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Forer {
      uint public value;
      
      function forer() public returns (bool yourMom) {
        bool a;
        bool b;
        bool c;
        c = !c;
        c = a && b;
        c = a || b;
        return c;
      }
    }
    """#"
    text_o = """
    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct Forer {
      let mut value:u64;
    }
    #[near_bindgen]
    impl Forer {
      pub fn forer(&mut self):bool {
        let mut a:bool;
        let mut b:bool;
        let mut c:bool;
        c = !(c);
        c = (a && b);
        c = (a || b);
        return c;
      }
    }
    ;
    """#"
    make_test text_i, text_o
  
  it 'uint ops', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Forer {
      uint public value;
      
      function forer() public returns (uint yourMom) {
        uint a = 0;
        uint b = 0;
        uint c = 0;
        bool bb;
        c = a + b;
        c = a - b;
        c = a * b;
        c = a / b;
        c = a % b;
        c = a & b;
        c = a | b;
        c = a ^ b;
        c = a << b;
        c = a >> b;
        c++;
        ++c;
        c--;
        --c;
        c = a;
        c = ~a;
        c += a;
        c -= a;
        c *= a;
        c /= a;
        bb = a == b;
        bb = a != b;
        bb = a <  b;
        bb = a <= b;
        bb = a >  b;
        bb = a >= b;
        return c;
      }
    }
    """#"
    text_o = """
      #[near_bindgen]
      #[derive(Default, BorshDeserialize, BorshSerialize)]
      pub struct Forer {
        let mut value:u64;
      }
      #[near_bindgen]
      impl Forer {
        pub fn forer(&mut self):u64 {
          let mut a:u64 = 0;
          let mut b:u64 = 0;
          let mut c:u64 = 0;
          let mut bb:bool;
          c = (a + b);
          c = (a - b);
          c = (a * b);
          c = (a / b);
          c = (a % b);
          c = (a & b);
          c = (a | b);
          c = (a ^ b);
          c = (a << b);
          c = (a >> b);
          c+=1;
          c+=1;
          c-=1;
          c-=1;
          c = a;
          c = ~(a);
          c += a;
          c -= a;
          c *= a;
          c /= a;
          bb = (a == b);
          bb = (a != b);
          bb = (a < b);
          bb = (a <= b);
          bb = (a > b);
          bb = (a >= b);
          return c;
        }
      }
      ;
    """#"
    make_test text_i, text_o
  
  it 'int ops', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      int public value;
      
      function forer() public returns (int yourMom) {
        int a = 1;
        int b = 1;
        int c = 1;
        bool bb;
        c = -c;
        c = ~c;
        c = a + b;
        c = a - b;
        c = a * b;
        c = a / b;
        c = a % b;
        c = a & b;
        c = a | b;
        c = a ^ b;
        c = a << b;
        c = a >> b;
        c++;
        ++c;
        c--;
        --c;
        bb = a == b;
        bb = a != b;
        bb = a <  b;
        bb = a <= b;
        bb = a >  b;
        bb = a >= b;
        return c;
      }
    }
    """#"
    text_o = """
      #[near_bindgen]
      #[derive(Default, BorshDeserialize, BorshSerialize)]
      pub struct Forer {
        let mut value:i64;
      }
      #[near_bindgen]
      impl Forer {
        pub fn forer(&mut self):i64 {
          let mut a:i64 = 1;
          let mut b:i64 = 1;
          let mut c:i64 = 1;
          let mut bb:bool;
          c = -(c);
          c = ~(c);
          c = (a + b);
          c = (a - b);
          c = (a * b);
          c = (a / b);
          c = (a % b);
          c = (a & b);
          c = (a | b);
          c = (a ^ b);
          c = (a << b);
          c = (a >> b);
          c+=1;
          c+=1;
          c-=1;
          c-=1;
          bb = (a == b);
          bb = (a != b);
          bb = (a < b);
          bb = (a <= b);
          bb = (a > b);
          bb = (a >= b);
          return c;
        }
      }
      ;
    """#"
    make_test text_i, text_o
  
  it 'a[b]', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      mapping (address => uint) balances;
      
      function forer(address owner) public returns (uint yourMom) {
        return balances[owner];
      }
    }
    """#"
    text_o = """
    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct Forer {
      let mut balances:HashMap<String,u64>;
    }
    #[near_bindgen]
    impl Forer {
      pub fn forer(&mut self, owner:String):u64 {
        return self.balances.get(owner).or_else(0);
      }
    }
    ;
    """#"
    make_test text_i, text_o
  
  it 'maps', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        balances[owner] += 1;
        return balances[owner];
      }
    }
    """#"
    text_o = """
    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct Forer {
      let mut balances:HashMap<String,i64>;
    }
    #[near_bindgen]
    impl Forer {
      pub fn forer(&mut self, owner:String):i64 {
        self.balances.insert(owner, (self.balances.get(owner).or_else(0) + 1));
        return self.balances.get(owner).or_else(0);
      }
    }
    ;
    """#"
    make_test text_i, text_o
  
  it 'while', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        int i = 0;
        while(i < 5) {
          i += 1;
        }
        return i;
      }
    }
    """#"
    text_o = """
    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct Forer {
      let mut balances:HashMap<String,i64>;
    }
    #[near_bindgen]
    impl Forer {
      pub fn forer(&mut self, owner:String):i64 {
        let mut i:i64 = 0;
        while (i < 5) {
          i += 1;
        } ;
        return i;
      }
    }
    ;
    """#"
    make_test text_i, text_o
  
  it 'for', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        int i = 0;
        for(i=2;i < 5;i++) {
          i += 1;
        }
        return i;
      }
    }
    """#"
    text_o = """
    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct Forer {
      let mut balances:HashMap<String,i64>;
    }
    #[near_bindgen]
    impl Forer {
      pub fn forer(&mut self, owner:String):i64 {
        let mut i:i64 = 0;
        i = 2;
        while (i < 5) {
          i += 1;
          i+=1;
        };
        return i;
      }
    }
    ;
    """#"
    make_test text_i, text_o
  
  it 'for no init and incr', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        int i = 0;
        for(;i < 5;) {
          i += 1;
          break;
        }
        return i;
      }
    }
    """#"
    text_o = """
    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct Forer {
      let mut balances:HashMap<String,i64>;
    }
    #[near_bindgen]
    impl Forer {
      pub fn forer(&mut self, owner:String):i64 {
        let mut i:i64 = 0;
        while (i < 5) {
          i += 1;
          break;
        };
        return i;
      }
    }
    ;
    """#"
    make_test text_i, text_o
  
  it 'for init var_decl', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      uint public value;
      
      function forer() public returns (uint yourMom) {
        uint y = 0;
        for (uint i=0; i<5; i+=1) {
            y += 1;
        }
        return y;
      }
    }
    """#"
    text_o = """
    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct Forer {
      let mut value:u64;
    }
    #[near_bindgen]
    impl Forer {
      pub fn forer(&mut self):u64 {
        let mut y:u64 = 0;
        let mut i:u64 = 0;
        while (i < 5) {
          y += 1;
          i += 1;
        };
        return y;
      }
    }
    ;
    """#"
    make_test text_i, text_o
  
  it 'continue break', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        int i = 0;
        for(i=2;i < 5;i++) {
          i += 1;
          continue;
          break;
        }
        return i;
      }
    }
    """#"
    text_o = """
    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct Forer {
      let mut balances:HashMap<String,i64>;
    }
    #[near_bindgen]
    impl Forer {
      pub fn forer(&mut self, owner:String):i64 {
        let mut i:i64 = 0;
        i = 2;
        while (i < 5) {
          i += 1;
          i+=1;
          continue;
          break;
          i+=1;
        };
        return i;
      }
    }
    ;
    """#"
    make_test text_i, text_o
  
  it 'fn call', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      function call_me(int a) public returns (int yourMom) {
        return a;
      }
      function forer(int a) public returns (int yourMom) {
        return call_me(a);
      }
    }
    """#"
    text_o = """
    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct Forer {
      
    }
    #[near_bindgen]
    impl Forer {
      pub fn call_me(&mut self, a:i64):i64 {
        return a;
      }
      pub fn forer(&mut self, a:i64):i64 {
        return call_me(a);
      }
    }
    ;
    """#"
    make_test text_i, text_o
  
  it 'struct', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Struct {
      uint public value;
      
        struct User {
            uint experience;
            uint level;
            uint dividends;
        }
      
      function ifer() public {
        User memory u = User(1, 2, 3);
        u.level = 20;
      }
    }
    """#"
    text_o = """
    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct User {
      experience:u64;
      level:u64;
      dividends:u64;
    }


    #[near_bindgen]
    #[derive(Default, BorshDeserialize, BorshSerialize)]
    pub struct Struct {
      let mut value:u64;
    }
    #[near_bindgen]
    impl Struct {
      pub fn ifer(&mut self):void {
        let mut u:User = User(1, 2, 3);
        u.level = 20;
      }
    }
    ;
    """#"
    make_test text_i, text_o