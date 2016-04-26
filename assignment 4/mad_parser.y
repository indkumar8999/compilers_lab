%{
#include <bits/stdc++.h>
#include "node.h"

#define SIMPLE 0
#define ARRAY 1
#define INT_SIZE 4
#define BOOL_SIZE 1
#define CHAR_SIZE 1

#define pretty_print_error yyerror
#define as_tree_n new node
#define lengthyy yyleng
#define textyy yytext
#define semicolon_error "Semicolon kadu"
#define comma_error "Comma kadu"
#define identifier_error " identifier kadu"
#define semicolon_error_for "Semicolon forlu kadu"
#define type_error "Unknown type declaration"
#define semicolon_error_return "Semicolon returnlo kadu :P"


#define vyavadhi scope
#define peru name
#define daram  string
#define dakshina code

using namespace std;

extern int yylex();
extern int lengthyy;
extern int yylineno;
extern char* textyy;

enum TYPE {VOIDF, INT, CHAR, BOOL, ERR};

struct var_record {
    bool is_param;
  	daram peru;
    int vyavadhi,var_type,dim,offset;
    TYPE type;
    daram mips_name;
};


struct func_record
{
    TYPE return_type;
    daram peru;
    vector<var_record> param_list;
    int paramlist_size;
};

//Attributes aakaramure
struct attr
{
    TYPE type;
    int ival;   //For storing values of constants
    char cval;
    float fval;
    bool bval;

    daram dakshina; //Code gen by diff non-terminals
    daram label; // Useful for if-else-operation
    vector<TYPE> types; //Types in parameter list
};


//GLOBAL VARIABLES FOR SEMANTIC ANALYSIS
int vyavadhi = 0;
int labelNumber = 0;
daram data;
vector< var_record > mips_name;
func_record *active_func_ptr, *call_name_ptr;
vector<var_record*> call_param_list;

//Tree printing
node *root;
bool arey_galti_hai_kya;

map<daram, func_record> func_table;
map<int, map<daram, var_record> > sym_table;

void pretty_print_error(const char*);
var_record* get_record (daram);
daram get_mips_name (var_record*);
daram load_mips_array(var_record* varRecord, int offSet);
daram store_mips_array(var_record* varRecord, int offSet);
int cast (TYPE typeA, TYPE typeB, int is_up); // Return type: 0-> no casting possible 1-> typeA can be casted 2-> typeB can be casted

//Function Declarations


void copy_attr( struct attr* A,struct attr* B){
  A->type = B->type;
  A->ival = B->ival;   //For storing values of constants
  A->cval = B->cval;
  A->fval = B->fval;
  A->bval = B->bval;

  A->dakshina = B->dakshina; //Code gen by diff non-terminals
  A->label = B->label; // Useful for if-else-operation

}


daram get_data_string(){
    stringstream data_string;
    data_string << '\n';
    set <daram> temp_mips_name;
    for(int i=0;i<mips_name.size();i++){
        var_record rec = mips_name[i];
        if (temp_mips_name.count( rec.mips_name ) ==0)
        {
          // peru
          temp_mips_name.insert(rec.mips_name);
          data_string << rec.mips_name << ": ";
          if(rec.var_type == SIMPLE){
              if(rec.type == INT){
                  data_string << ".word ";
                  data_string << "0";
              }
              else{
                  data_string << ".byte ";
                  data_string << "0x41";
              }
          }
          else{
              data_string << ".space ";
              if(rec.type == INT){
                  data_string << (rec.dim)*4;
              }
              else{
                  data_string << rec.dim;
              }
          }
          data_string << "\n";
        }

    }
    return data_string.str();
}

var_record* get_record(daram peru)
{
    for(int i=vyavadhi;i>=2;i--)
    {
        if (sym_table[i].find(peru) != sym_table[i].end())
        {
            return &sym_table[i][peru];
        }
    }
    return NULL;
}

daram get_mips_name (var_record* varRecord)
{
    daram mips_name;
    if (active_func_ptr == NULL){
      mips_name = "main";
    }
    else{
      mips_name = active_func_ptr -> peru;
    }
    mips_name += "_";
    mips_name += varRecord-> peru;

    stringstream s;//int ko string karne ka aur koi raasta nahe mila
    s << "_" << varRecord->type << "_" << varRecord->vyavadhi ;
    mips_name += s.str();
    return mips_name;
}


daram get_label()
{
    //Only returns the peru of the label
	stringstream s;//int ko string karne ka aur koi raasta nahe mila
	s << labelNumber;
    daram label =  "LABEL" + s.str();
    labelNumber++;
    return label;
}

daram load_mips_array(var_record* varRecord, int offSet)
{
    daram loadCode,loadType;
    int eleSize;
    if (varRecord->type == INT){
        eleSize = 4;
        loadType = "lw";
    }
    else if (varRecord -> type == BOOL || varRecord -> type == CHAR){
        eleSize = 1;
        loadType = "lb";
    }
    else{
        printf("Incorrect type of array in load.\n");
        exit(1);
    }
    stringstream s,s1;
    s << offSet;
    s1 << eleSize;
    loadCode = "li $t1 " + s.str() + "\n" ;
    loadCode += "li $t2 " + s1.str() + "\n";
    loadCode += "mul $t2 $t1 $t2\n" ;
    loadCode += "la $t1 " + get_mips_name(varRecord) + "\n";
    loadCode += "add $t1 $t1 $t2 \n";
    loadCode += loadType + " $t0 ($t1) \n";
    return loadCode;
}

daram store_mips_array(var_record* varRecord, int offSet)
{
    daram storeCode,storeType;
    int eleSize;
    if (varRecord->type == INT){
        eleSize = 4;
        storeType = "sw";
    }
    else if (varRecord -> type == BOOL || varRecord -> type == CHAR){
        eleSize = 1;
        storeType = "sb";
    }
    else{
        printf("Incorrect type of array in store.\n");
        exit(1);
    }
    stringstream s,s1;
    s << offSet;
    s1 << eleSize;
    storeCode = "li $t1 " + s.str() + "\n" ;
    storeCode += "li $t2 " + s1.str() + "\n";
    storeCode += "mul $t2 $t1 $t2\n" ;
    storeCode += "la $t1 " + get_mips_name(varRecord) + "\n";
    storeCode += "add $t1 $t1 $t2 \n";
    storeCode +=  storeType + " $t0 ($t1)\n";
    return storeCode;
}

daram load_mips_id(var_record* varRecord)
{
    daram loadCode,loadType;
    if (varRecord->type == INT){
        loadType = "lw";
    }
    else if (varRecord->type == BOOL || varRecord-> type == CHAR){
        loadType = "lb";
    }
    else{
        printf("Incorrect type of ID in load.\n");
        exit(1);
    }
    loadCode = loadType + " $t0 " + get_mips_name(varRecord) + "\n";
    return loadCode;
}

daram store_mips_id (var_record* varRecord)
{
    daram storeCode,storeType;
    if (varRecord->type == INT){
        storeType = "sw";
    }
    else if (varRecord->type == BOOL || varRecord->type == CHAR){
        storeType = "sb";
    }
    else{
        printf("Incorrect type of ID in load.\n");
        exit(1);
    }
    storeCode = storeType + " $t0 " + get_mips_name(varRecord) + "\n";
    return storeCode;
}

daram intToBool()
{
    daram boolCode = "srl $t0 $t0 0x1F\n";
    boolCode += "andi $t0 $t0 0x1\n";
    boolCode += "addi $t0 $t0 0x1\n";
    boolCode += "andi $t0 $t0 0x1\n";
    return boolCode;
}

int cast (TYPE pehla_waala_type, TYPE doosra_waala_type, int is_up)
{
    if (pehla_waala_type == doosra_waala_type)
        return 0;
    if (is_up == 1){
        /* char can be converted to int, bool can be converted to int */
        if ( (pehla_waala_type == CHAR || pehla_waala_type == BOOL) && doosra_waala_type == INT)
        {
            return 1;
        }
        else if ((doosra_waala_type == CHAR || doosra_waala_type == BOOL) && pehla_waala_type == INT){
            return 2;
        }
        return -1;
    }
    else{
        //int can be converted to bool
        if ( pehla_waala_type == BOOL && doosra_waala_type == INT ){
            return 2;
        }
        else if (pehla_waala_type == INT && doosra_waala_type == BOOL){
            return 1;
        }
        return -1;
    }
}

int are_comparable(TYPE typeA, TYPE typeB)
{
    //Bool-Char, Bool-Bool combinations can't be compared
    if ( (typeA == CHAR && typeB == BOOL) || (typeA == BOOL && typeB == CHAR) )
        return false;
    else return true;
}

node::node(daram con, node_type t)
{
	content = con;
	type = t;
	child = NULL;
	sibling = NULL;
	info = "";
}
//First SEGEMENT
node::node(const char* con, int t)
{
	content = (con);
	if(t == 0) type = NONTERM;
	else if(t == 1) type = TERM;
	else if(t == 2) type = VAL;
	info = "";
}

%}

%union{
	struct attr* attr_el;
	node* node_el;
	char* node_con;
}

%start start_mad_program

%token <node_con> ID
%token COMMA
%token SEMI
%token OPENPAREN
%token CLOSEPAREN
%token OPENCURLY
%token CLOSECURLY
%token OPENSQUARE
%token CLOSESQUARE
%token OPENNEGATE
%token VOID
%token DTYPE_INT
%token DTYPE_BOOL
%token DTYPE_CHAR
%token <node_con> EQ
%token <node_con> ARITH
%token <node_con> RELN
%token <node_con> LOGICAL
%token <node_con> LOGICALNOT
%token IF
%token ELSE
%token WHILE
%token FOR
%token RETURN
%token PRINT
%token READ
%token <node_con> BOOLCONST
%token <node_con> INTCONST
%token <node_con> CHARCONST

%token NONTERMINAL 0
%token TERMINAL 1
%token VALUE 2

%type <attr_el> mad_program supported_declarations variable_declarations function_declarations variable_definitions dtype argument_list statement_block
%type <attr_el> variable_list statement_list supported_statement if_statement else_statement while_statement return_statement
%type <attr_el> var_decl var_use id_list supported_constant alr_subexpression lhs func_name comma_rule

%%

start_mad_program:
  mad_program{
    cout <<".data\n";
    cout << get_data_string();
    cout <<"\n .text \n .globl main \n";
    cout << $1->dakshina;
  }

mad_program:
	supported_declarations {
  	$$ = new attr(); copy_attr($$,$1);
  }
	| supported_declarations mad_program {
  	$$ = new attr(); copy_attr($$,$1);
    $$->dakshina += $2->dakshina;
  }
	| error '\n' { pretty_print_error("Compilation terminating with errors"); root = NULL;}

supported_declarations:
	variable_declarations {
  	$$ = new attr(); copy_attr($$,$1);
  }
	| function_declarations {
  	$$ = new attr(); copy_attr($$,$1);
  }

variable_declarations:
	variable_definitions SEMI {
    $$ = new attr(); copy_attr($$,$1);
  }
//	| variable_definitions error { $$ = new attr(); $$->type = ERR; pretty_print_error(semicolon_error); }

variable_definitions:
	dtype var_decl {
    $$ = new attr();
  	if (arey_galti_hai_kya)
    {
    	$$->type = ERR;
      $$->dakshina = "";
    }
  	else
    {
    	$$->dakshina = $2->dakshina;
      $$->type = $1->type;

    }

}
	| variable_definitions comma_rule var_decl {
    $$ = new attr();
  	if (arey_galti_hai_kya)
    {
    	$$->type = ERR;
      $$->dakshina = "";
    }
  	else
    {
      $3->type = $2->type;
    	$$->dakshina = $1->dakshina + $3->dakshina;
      $$->type = $2->type;
    }
  	}
	| variable_definitions error var_decl '\n' { $$ = new attr(); $$->type = ERR; pretty_print_error("Missing comma in definitions list"); }

comma_rule:
  COMMA {$$ = new attr(); $$->type = ($<attr_el>0)->type; }

dtype:
	DTYPE_INT {
    $$ = new attr();
    $$->type = INT;
    $$->ival = INT_SIZE;
  }
	| DTYPE_BOOL {
    $$ = new attr();
    $$->type = BOOL;
    $$->ival = BOOL_SIZE;
  }
	| DTYPE_CHAR {
  	$$ = new attr();
    $$->type = CHAR;
    $$->ival = CHAR_SIZE;
  }
	// | error {
  //   $$ = new attr();
  //   $$->type = ERR;
  //   $$->ival = -1;
  //   pretty_print_error(type_error);
  // }

function_declarations:
	dtype func_name  OPENPAREN { vyavadhi = 1; } argument_list CLOSEPAREN statement_block {
        //vyavadhi Consideration
        vyavadhi = 0;
    		int cur_offset = 0;
        //Semantic
        $$ = new attr();

        // for ( int i = 0; i < active_func_ptr->param_list.size(); i++ )
        // {
        // 	switch(active_func_ptr->param_list[i].type)
        //   {
        //   	case INT: active_func_ptr->param_list[i].offset = cur_offset + INT_SIZE;
        //               cout << "\t " << active_func_ptr->param_list[i].offset << " peru: " << active_func_ptr->param_list[i].peru << endl;
        //     				cur_offset += INT_SIZE;
        //     	break;
        //     default: active_func_ptr->param_list[i].offset = cur_offset + BOOL_SIZE;
        //     				cur_offset += BOOL_SIZE;
        //     break;
        //   }
        // }
    		active_func_ptr->paramlist_size = $5->ival ; //Setting paramlist size
        //Code Generation
        $$->dakshina = $2->label + ":\n";
        //Store return $ra to stack and set frame pointer to $ra
        $$->dakshina += "sw $ra 0($sp)\n";
        $$->dakshina += "move $fp $sp \n";
    		$$->dakshina += "addiu $sp $sp -4\n";
    		$$->dakshina += $7->dakshina;
        $$->dakshina += "lw $ra 0($fp)\n";
        $$->dakshina += "move $sp $fp\n";

    		//Pop parameters
    		stringstream s;//int ko string karne ka aur koi raasta nahe mila
    		s << active_func_ptr->paramlist_size;
    		$$->dakshina += "addiu $sp $sp " + s.str() + "\n";
        $$->dakshina += "lw $fp 4($sp)\n";
        $$->dakshina += "addiu $sp $sp 4\n";
    		$$->dakshina += "jr $ra\n";
    		//Semantic again
    		active_func_ptr = NULL;
	}
	| VOID {$<attr_el>$ = new attr(); $<attr_el>$-> type = VOIDF; } func_name { vyavadhi = 1; } OPENPAREN argument_list CLOSEPAREN statement_block {
		//vyavadhi Consideration
		vyavadhi = 0;

		//Semantic
    $$ = new attr();
    //vyavadhi Consideration
        vyavadhi = 0;
    		int cur_offset = 0;
        //Semantic
        $$ = new attr();
    		active_func_ptr->paramlist_size = $6->ival; //Setting paramlist size
    //Code Generation
    		$$->dakshina = $3->label + ":\n";
        //Store return $ra to stack and set frame pointer to $ra
        $$->dakshina += "sw $ra 0($sp) \n";
        $$->dakshina += "move $fp $sp \n";
    		$$->dakshina += "addiu $sp $sp -4\n";
    		$$->dakshina += $8->dakshina;
    		$$->dakshina += "move $sp $fp\n";
    		$$->dakshina += "lw $ra 0($fp)\n";          // $ra <- 0($fp)
    		$$->dakshina += "addiu $sp $sp 4\n";
    		//Pop parameters
    		stringstream s;//int ko string karne ka aur koi raasta nahe mila
    		s << active_func_ptr->paramlist_size;
    		$$->dakshina += "addiu $sp $sp " + s.str() + "\n";
    		$$-> dakshina += "jr $ra\n";

    		//Semantic again
    		active_func_ptr = NULL;
	}
func_name:
	ID {
    $$ = new attr();
		if (func_table.count($1) > 0)
    {
    	arey_galti_hai_kya = true;
      pretty_print_error ("Sem mein galti: function k liye naam khatam ho gye kya :P");
    }
    else
    {
    	func_record f_temp;
      func_table[daram($1)] = f_temp;
      //Setting active_func_ptr
      active_func_ptr = &func_table[daram($1)];
      active_func_ptr -> peru = daram($1);
      active_func_ptr -> return_type = $<attr_el>0->type;
    }
    $$->type = VOIDF;
    $$->label = $1;
  }
argument_list:
		 dtype var_decl COMMA argument_list {
      //Nothing to do - check for errors and proceed
      $$ = new attr();
      if (arey_galti_hai_kya)
      {
        $$->type = ERR;
        $$->dakshina = "";
      }
      else
      {
        active_func_ptr->param_list[$2->ival].offset = $4->ival + ( $1->ival );
        // cout << active_func_ptr->param_list[$2->ival].peru << " has offset " << active_func_ptr->param_list[$2->ival].offset << endl;
        $$->dakshina = $1->dakshina + $2->dakshina;
        $$->ival = $4->ival + ($1->ival);
      }
  }
  |%empty /*epsilon production*/ {
    //Nothing to do
    $$ = new attr();
    $$->dakshina = "";
    $$->ival = 0;
  }
	| dtype ID error argument_list {
  	arey_galti_hai_kya = true;
    pretty_print_error (comma_error);
    $$ = new attr();
    $$->type = ERR;
  }
	| dtype error COMMA argument_list {
  	arey_galti_hai_kya = true;
    pretty_print_error (identifier_error);
    $$ = new attr();
    $$->type = ERR;
  }

statement_block:
opencurly variable_list statement_list CLOSECURLY {
		$$ = new attr();

  	if (arey_galti_hai_kya)
    {
    	$$->type = ERR;
      $$->dakshina = "";
    }
  	else
    {
    	$$->dakshina = $2->dakshina + $3->dakshina;
    }
  	//vyavadhi resolution
    map<daram, var_record> temp;
  	sym_table[vyavadhi] = temp;
  	vyavadhi--;
  }

//Seond SEGEMENT

	// | OPENCURLY variable_list statement_list error {
  // 	arey_galti_hai_kya = true;

  //   $$ = new attr();
  //   $$->type = ERR;
  // }

opencurly:
  OPENCURLY { vyavadhi++; }

variable_list:
	%empty /*epsilon production*/ {
  	//Nothing to do
    $$ = new attr();
    $$->dakshina = "";

  }
	| variable_declarations variable_list {
    //Nothing to do - check for error in further productions
    $$ = new attr();

    if (arey_galti_hai_kya)
    {
      $$->type = ERR;
      $$->dakshina = "";
    }
    else
      $$->dakshina = $1->dakshina + $2->dakshina;
  }


statement_list:
	%empty {
    //Nothing to do
    $$ = new attr();
    $$->dakshina = "";

  }
	| supported_statement statement_list {
    //Semantic Analyses - chaining
    $$ = new attr();
    if (!arey_galti_hai_kya)
    {
    	$$->dakshina = $1->dakshina + "\n" + $2->dakshina;
    }
    else
    {
      $$->type = ERR;
      $$->dakshina = "";
    }
  }

supported_statement:
	alr_subexpression SEMI {
    //Nothing to do
    $$ = new attr(); copy_attr($$,$1);
  }
	| if_statement {
    //Nothing to do
    $$ = new attr(); copy_attr($$,$1);
  }
	| while_statement {
    //Nothing to do
    $$ = new attr(); copy_attr($$,$1);
  }
	| return_statement {
    //Nothing to do
    $$ = new attr(); copy_attr($$,$1);
  }
	| statement_block {
    //Nothing to do
    $$ = new attr(); copy_attr($$,$1);
  }
	| alr_subexpression error { $$ = new attr(); $$->type = ERR; arey_galti_hai_kya = true; pretty_print_error("Possible missing semicolon with alr_subexpression"); }

if_statement:
	IF OPENPAREN alr_subexpression CLOSEPAREN statement_block else_statement {
		$$ = new attr();
		if ($3->type == CHAR )
    {
    	arey_galti_hai_kya = true;
      $$->type = ERR;
      pretty_print_error ("Incompatible types: if mein boolean value dene ka, nahe toh apun error dega.");
    }
		//Code Generation
	    daram startElse,endElse;
	    startElse = get_label();
	    endElse = get_label();

	    $$ -> dakshina = $3-> dakshina;
      if ($3->type == INT){
        $$->dakshina += intToBool();
      }
	    $$ -> dakshina += "li $t1 0x1\n";
	    $$ -> dakshina += "bne $t0 $t1 " + startElse + "\n";
	    $$ -> dakshina += $5 ->dakshina;
	    $$ -> dakshina += "b " + endElse + "\n";
	    $$ -> dakshina += startElse + ":\n";
	    $$ -> dakshina += $6->dakshina;
	    $$ -> dakshina += endElse + ":\n";

	}

else_statement:
	%empty {
    	$$ = new attr();
    	//Semantic Analyses - no check
    	//CodeGen
	    $$-> dakshina = "\n";
	}
	| ELSE statement_block {
		$$ = new attr();
    //Semantic Analyses - no check
		//Code Generation
		$$->dakshina = $2->dakshina;

	}

while_statement:
	WHILE OPENPAREN alr_subexpression CLOSEPAREN statement_block {
    $$ = new attr();
    //Semantic Analyses
    if ($3->type != BOOL)
    {
    	arey_galti_hai_kya = true;
      $$->type = ERR;
      pretty_print_error ("Incompatible types: while mein boolean value dene ka nahe toh apan error dega");
    }

		//Code Generation
    if (!arey_galti_hai_kya)
    {
      daram startWhile = get_label();
      daram endWhile = get_label();
      //Start While loop
      $$->dakshina = startWhile + ":\n";
      //Evaluate alr_subexpression
      $$->dakshina += $3->dakshina;
      $$->dakshina += "li $t1 0x1\n";
      $$->dakshina += "bne $t0 $t1 " + endWhile + "\n";
      //Perform main Statement Block
      $$->dakshina += $5->dakshina;
      $$->dakshina += "b " + startWhile + "\n";
      //FinishWhile
      $$->dakshina += endWhile + ":\n";
    }
	}

return_statement:
	RETURN SEMI {
    $$ = new attr();
    //Semantic Analyses
		if ( active_func_ptr->return_type != VOIDF )
    {
      		$$->type = ERR;
          arey_galti_hai_kya = true;
          pretty_print_error("Incompatible types: function return type not void");
    }

    //Code Generation
    //Nothing to do

	}
	| RETURN alr_subexpression SEMI {
    	$$ = new attr();
    	//Semantic Analyses
    	copy_attr($$,$2);
      // cout << active_func_ptr-> peru << " HYT "<< func_table[active_func_ptr->peru].return_type << endl ;
      // cout << $2->type << " " << active_func_ptr->return_type << endl;
    	int downcast_needed = cast(active_func_ptr->return_type, $2->type, 0);
      if ( active_func_ptr->return_type != $2->type )
      {
        if (downcast_needed < 0 || (downcast_needed == 2 && $2->type == CHAR) )
        {
          $$->type = ERR;
          arey_galti_hai_kya = true;
          pretty_print_error("Incompatible types: function return type and returned expression");
        }
        else
        {
        	//CodeGen - extra
        	$$->dakshina += intToBool();
        }
      }
	}
	| RETURN error {  $$ = new attr(); $$->type = ERR; pretty_print_error(semicolon_error_return); }
	| RETURN alr_subexpression error {  $$ = new attr(); $$->type = ERR; pretty_print_error(semicolon_error_return); }

alr_subexpression:
	 supported_constant {
        // $$= new attr();
	   //Semantic analyses - Nothing to check
	   $$ = new attr(); copy_attr($$,$1);

	   //CodeGen


	}
	| var_use
    {
      //  $$= new attr();

	   //Semantic analyses - Nothing to check
     $$ = new attr(); copy_attr($$,$1);

	   //CodeGen - Nothing to do


	}
	| ID OPENPAREN id_list CLOSEPAREN  { //Function call

          $$= new attr();
        //Semantic analyses
    		call_name_ptr = NULL;
        if ( func_table.count($1) == 0 )
        {
            $$->type = ERR;
            arey_galti_hai_kya = true;
            pretty_print_error("Sem mein galti: Arey function toh declare kar do bhai.");
        }
    		else
          call_name_ptr = &func_table[$1];
          // cout << call_param_list.size() <<"-call_param_list size && " << call_name_ptr->param_list.size() << endl;
    		if ( call_name_ptr->param_list.size() != call_param_list.size() )
        {
            $$->type = ERR;
            arey_galti_hai_kya = true;
            pretty_print_error("Sem mein galti: Upar kuch aur declare karto ho ,neeche kch aur parameter ki list dekh k use karo.");
        }
        else
        {
            for ( int i = 0; i < call_param_list.size(); i++ )
            {
                // cout << " call_param_list: " << call_param_list[i]->peru << " " << call_param_list[i]->type << endl;
                // cout << " call_name_ptr ki list:  " << ca

                if ( call_param_list[i]->type != call_name_ptr->param_list[i].type )
                {
                    arey_galti_hai_kya = true;
                    $$->type = ERR;
                    pretty_print_error ("Sem mein galti: Parameter type enti? mis_match_in_parameter_list");
                }
            }
        }
    		$$->type = call_name_ptr->return_type;

        //CodeGeneration
        // $$->type = func_table[$1].return_type;
    		$$->dakshina = "sw $fp 0($sp) \n"; // $fp -> 0($sp)
        $$->dakshina += "addiu $sp $sp -4\n";
    		daram eleType;
    		int eleSize;
        for (int i=0;i< call_param_list.size(); i++){

          if (call_param_list[i]->type == INT){
          	eleType = "lw";
            eleSize = 4;
          }
          else{
           	eleType = "lb";
            eleSize = 1;
          }
            if (call_param_list[i]->is_param == true){
              	stringstream s;//int ko string karne ka aur koi raasta nahe mila
              	s << call_param_list[i]->offset;
            		$$->dakshina += eleType + " $t1 " + s.str() + "($fp) \n";
            }
          else{
               $$->dakshina += eleType + " $t1 " + get_mips_name(call_param_list[i]) + "\n";
          }
          $$->dakshina += "sw $t1 0($sp)\n";
          stringstream s1; s1 <<eleSize;
					$$->dakshina += "addiu $sp $sp -" + s1.str() + "\n";
        }
    		$$->dakshina += "jal " +daram($1) + "\n";

				//Back to Semantic
        call_name_ptr = NULL;
  }
	| OPENPAREN alr_subexpression CLOSEPAREN {
		//Semantic Analyses - no checks needed
		//CodeGen
    $$ = new attr();
		copy_attr($$,$2);
  }
	| alr_subexpression ARITH alr_subexpression {

        $$ = new attr();
        // cout<< $1->type << " " << $4->type <<endl;
	    //Semantic Analyses
      //cout << $1->type << "\t"<< $1->dakshina <<endl;
	    if (cast($1->type, $3->type, 1) < 0)
	    {
	        arey_galti_hai_kya = 1;
	        $$->type = ERR;
	        pretty_print_error ("Sem mein galti: Arithmetic operation barabar waalo p lagaao");
	    }

//Third SEGEMENT

	    //Code Generation
	    if (!arey_galti_hai_kya){
        $$->dakshina = $1->dakshina;
        $$->dakshina += "sw $t0 0($sp) \n";
        $$->dakshina += "addiu $sp $sp -4\n";
        $$->dakshina +=  $3->dakshina;
        $$->dakshina += "lw $t1 4($sp)\n";
        $$->dakshina += "addiu $sp $sp 4\n";
        // cout << $2 << " " << ($2 == "+") <<endl;
	        if (daram($2) == daram("+")){
	            $$->dakshina += "add $t0 $t0 $t1\n";
	        }
	        else if ( daram($2) == daram("-")){
	            $$->dakshina += "sub $t0 $t1 $t0\n";
	        }
	        else if ( daram($2) == daram("*")){
	            $$->dakshina += "mul $t0 $t0 $t1\n";
	        }
	        else if ( daram($2) == daram("/")){
	            $$->dakshina += "div $t0 $t1 $t0\n";
	        }
        $$->type = INT;
	    }
	}
	| OPENNEGATE alr_subexpression CLOSEPAREN {
        $$= new attr();
		//Semantic analyses - no checks
		$$ = $2;
		//Code gen
		if(!arey_galti_hai_kya){
		    $$->dakshina += "neg $t0 $t0 \n";
		}
	}
	| alr_subexpression   RELN alr_subexpression {
        $$ = new attr();
	    //Semantic Analyses
	    if ( !are_comparable($1->type, $3->type) )
	    {
	        arey_galti_hai_kya = true;
	        $$->type = ERR;
	        pretty_print_error ("Sem mein galti: Relational barabari barabar waalo k saath karo");
	    }

		//Code Generation
		if (!arey_galti_hai_kya){
		    $$->type = BOOL;
        $$->dakshina = $1->dakshina;
        $$->dakshina += "sw $t0 0($sp) \n";
        $$->dakshina += "addiu $sp $sp -4\n";
        $$->dakshina += $3->dakshina;
        $$->dakshina += "lw $t1 4($sp)\n";
        $$->dakshina += "addiu $sp $sp 4\n";
	        if (daram($2) == daram("==") ){
	            $$->dakshina += "seq $t0 $t1 $t0\n";
	        }
	        else if (daram($2) == daram("<") ){
	            $$->dakshina += "slt $t0 $t1 $t0\n";
	        }
	        else if ( daram($2) == daram("<=")){
	            $$->dakshina += "sle $t0 $t1 $t0\n";
	        }
	        else if (daram($2) == daram(">")){
	            $$->dakshina += "sgt $t0 $t1 $t0\n";
	        }
	        else if (daram($2) == daram(">=")){
	            $$->dakshina += "sge $t0 $t1 $t0\n";
	        }
	        else if (daram($2) == daram("!=")){
	            $$->dakshina += "seq $t0 $t1 $t0\n";
	            $$->dakshina += "xori $t0 $t0 0x1\n";
	        }

		}
	}

	| alr_subexpression LOGICAL alr_subexpression {
        $$ = new attr();
        //Semantic Analyses
        if ( ($1->type == CHAR || $3->type == CHAR) )
        {
            arey_galti_hai_kya = true;
            $$->type = ERR;
            pretty_print_error ("Sem mein galti: Gotcha !! char ko bool ki tarah mat use karo yaar.");
        }
        //Code Generation
        if (!arey_galti_hai_kya){
            $$->type = BOOL;

            $$->dakshina = $1->dakshina;
            if ($1->type == INT){
              $$->dakshina += intToBool();
            }
            $$->dakshina += "sw $t0 0($sp) \n";
            $$->dakshina += "addiu $sp $sp -4\n";
            $$->dakshina += $3->dakshina;

          if ($3->type == INT){
	            $$->dakshina += intToBool();
	        }
            $$->dakshina += "lw $t1 4($sp)\n";
            $$->dakshina += "addiu $sp $sp 4\n";

            if (daram($2) == daram("&&")){
                $$->dakshina += "and $t0 $t0 $t1\n";
            }
            else if (daram($2) == daram("||")){
                $$->dakshina += "or $t0 $t0 $t1\n";
            }

        }
	}
	| LOGICALNOT alr_subexpression {
    $$  = new attr();
		if ($2->type == CHAR)
		{
		    arey_galti_hai_kya = true;
		    $$->type = ERR;
            pretty_print_error ("Sem mein galti: Phir se. !CHAR allowed nahe h bhai.");
		}

		//Code Generation
		if (!arey_galti_hai_kya){
        $$->type = BOOL;
		    $$->dakshina = $2->dakshina;
		    if ($2->type == INT){
		        $$->dakshina+= intToBool();
		    }
		    $$->dakshina += "xori $t0 $t0 0x1\n";
		}
	}
  | lhs EQ alr_subexpression {
        $$= new attr();
        //Semantic
        // if ($1->type == INT && $3->type == CHAR){
        //   cout << "pahuch gaya."<<endl;
        // }
        // cout << $1->type <<" \t " << $3->type <<endl;
        if ( ($1->type == CHAR && $3->type != CHAR) || ($1->type == BOOL && $3->type == CHAR ) )
        {
          $$->type = ERR;
	        $$->ival = -1;
	        pretty_print_error("Sem mein galti: equality: barabar waalo k saath");
	        arey_galti_hai_kya = true;
        }

        //Code Generation
        if (!arey_galti_hai_kya)
        {
            var_record *lhsRecord = get_record($1->dakshina);
            $$ -> dakshina = $3->dakshina;


            if ( cast($1->type, $3->type, 0) == 2)
            {
                //CodeGen - no other casting test needed because only allowed downcast is from int to bool
                $$->dakshina += "#Casting of RHS\n";
                $$->dakshina += intToBool();
            }
            if ( $1->type != ERR && $1->dakshina == "$" )
            {
                lhsRecord = &active_func_ptr->param_list[$1->ival];
                stringstream s;//int ko string karne ka aur koi raasta nahe mila
                s << lhsRecord->offset;
                $$->dakshina += "sw $t0 " + s.str() + "($fp) \n";
            }

            if ($1->ival == -1 && $1->type != ERR ){
                  //ID
                  $$->dakshina += store_mips_id(lhsRecord);

              }
              else if ($1->type != ERR){
                  //ID[const]
                  $$->dakshina += store_mips_array(lhsRecord,$1->ival);
              }
        }
	}

	| error EQ alr_subexpression { $$ = new attr(); $$->type = ERR; pretty_print_error("Missing identifier peru"); }


id_list:
	id_list COMMA var_use {
	   //Semantic Analyses
     $$ = new attr();
	   $$ = new attr(); copy_attr($$,$1);
	   if ( $3->type != ERR )
     {
    		if ($3->bval)
        {
        	call_param_list.push_back(& (call_name_ptr->param_list[$3->ival]) );
        }
       else
       {
       		call_param_list.push_back( get_record($3->label) );
       }
     }

	   //CodeGen


	}
	| var_use {
      $$ = new attr();
	   //Semantic Analyses
	   $$ = new attr(); copy_attr($$,$1);
     if ( $1->type != ERR )
     {
    		if ($1->bval)
        {
        	call_param_list.push_back(& (call_name_ptr->param_list[$1->ival]) );
        }
       else
       {
       		call_param_list.push_back( get_record($1->label) );
       }
     }
    //  cout << "Last: " << call_param_list.back()->peru << endl ;
	   //CodeGen


	}
	| %empty {
      $$ = new attr();
	   //Semantic Analyses  - no checks needed
	   //CodeGen - nothing to do


	}



lhs:
    ID {
	    //Semantic Analyses -> param
      $$ = new attr();
	    var_record* id_rec = get_record($1);
	    if ( id_rec == NULL )
	    {
	        //Check if valid parameter
	        int flag = -1;
	        for ( int i = 0; i < active_func_ptr->param_list.size(); i++ )
	            if ( active_func_ptr->param_list[i].peru == $1 )
	                { flag = i; break; }
	        if (flag >= 0)
	        {
	            $$->type = active_func_ptr->param_list[flag].type;
	            $$->ival = flag;
	            $$->dakshina = "$";
	        }
	        else
	        {
	            $$->type = ERR;
    	        $$->ival = -1;
    	        pretty_print_error("Sem mein galti: Arey ID declare kar k use karo bhai");
    	        arey_galti_hai_kya = true;
	        }
	    }
	    else if ( id_rec->var_type != SIMPLE )
	    {
	        $$->type = ERR;
	        pretty_print_error("Sem Error:Don't try to access array as a unit scalar.");
	        arey_galti_hai_kya = true;
	    }
	    else
	    {
	        $$->type = id_rec->type;
	        $$->dakshina = $1;
	        $$->ival = -1;
	    }
	    //CodeGen
	    //No codegen



	}
	| ID OPENSQUARE INTCONST CLOSESQUARE {
        $$ = new attr();
        //Semantic Analyses
        var_record* id_rec = get_record($1);
        if ( id_rec == NULL )
        {
            $$->type = ERR;
	        pretty_print_error("Sem mein galti: Arey ID declare kar k use karo bhai");
	        arey_galti_hai_kya = true;
        }
        else if ( id_rec->var_type != ARRAY )
	    {
	        $$->type = ERR;
	        pretty_print_error("Sem mein galti: Don't try to access scalar as an Array.");
	        arey_galti_hai_kya = true;
	    }
	    else
	    {
	        int iconst = atoi($3);
	        if(iconst < 0 || iconst >= id_rec->dim)
	        {
	            $$->type = ERR;
	            pretty_print_error("Sem mein galti: Arre array se bahar chale gaye.");
	            arey_galti_hai_kya = true;
	        }
	        $$->type = id_rec->type;
	        $$->ival = iconst;
	        $$->dakshina = $1;
	    }

        //CodeGen
        //No dakshina generated in this production


	}

var_decl:
	ID {
	   // Semantic
    $$ = new attr();
    if (vyavadhi == 1)
    {
    	var_record id_rec;
      id_rec.is_param = true;
      id_rec.var_type = SIMPLE;
      id_rec.peru = $1;
      id_rec.vyavadhi = vyavadhi;
      id_rec.dim = 0;
      id_rec.type = ($<attr_el>0)->type;
      active_func_ptr->param_list.push_back(id_rec);
      $$->ival = active_func_ptr->param_list.size() - 1;
    }
    else
    {
       if( sym_table.count(vyavadhi) > 0 && sym_table[vyavadhi].count($1) != 0 )
       {
            $$->type = ERR;
            pretty_print_error("Sem mein galti: Kripya is ID ko scope k bahar ja dobara declare karo.");
            arey_galti_hai_kya = true;
       }
       else
       {
              var_record id_rec;
         			id_rec.is_param = false;
              id_rec.var_type = SIMPLE;
              id_rec.peru = $1;
              id_rec.vyavadhi = vyavadhi;
              id_rec.dim = 0;
              id_rec.type = ($<attr_el>0)->type;
              if (!sym_table.count(vyavadhi))
              {
                map <daram,var_record> temp;
                temp[$1] = id_rec;
                sym_table[vyavadhi] = temp;
              }
              else{
                sym_table[vyavadhi][$1] = id_rec;
              }
         			$$->ival = -1;
              //cout << id_rec.type <<"\t"<<id_rec.peru<<"\n";
              // cout << $1 << " inserted." << endl;
       }

       //CodeGen
       sym_table[vyavadhi][$1].mips_name = get_mips_name(&sym_table[vyavadhi][$1]);
       mips_name.push_back( sym_table[vyavadhi][$1] ); //For adding to data declarations
    }


	}
	| ID OPENSQUARE INTCONST CLOSESQUARE {
      $$ = new attr();
	   //Semantic
	   if( sym_table.count(vyavadhi) > 0 && sym_table[vyavadhi].count($1) != 0 )
	   {
	        $$->type = ERR;
	        pretty_print_error("Sem mein galti: Kripya is ID ko scope k bahar ja dobara declare karo.");
	        arey_galti_hai_kya = true;
	   }
	   else
	   {
            var_record id_rec;
       			id_rec.is_param = false;
            id_rec.var_type = ARRAY;
            id_rec.peru = $1;
            id_rec.vyavadhi = vyavadhi;
            id_rec.dim = atoi($3);
            id_rec.type = $<attr_el>0->type;
            sym_table[vyavadhi][$1] = id_rec;
	   }

       //CodeGen
     sym_table[vyavadhi][$1].mips_name = get_mips_name(&sym_table[vyavadhi][$1]);
	   mips_name.push_back(sym_table[vyavadhi][$1]); //For adding to data declarations


	}

var_use:
	ID {
	    //Semantic Analyses
      $$ = new attr();
    	bool is_param = false;
    	int flag = -1;
	    var_record* id_rec = get_record($1);
	    if ( id_rec == NULL )
	    {
	        for ( int i = 0; i < active_func_ptr->param_list.size(); i++ )
	            if ( active_func_ptr->param_list[i].peru == $1 )
	                { flag = i;break; }
	        if (flag >= 0)
	        {
             	is_param = true;
	            $$->type = active_func_ptr->param_list[flag].type;
            	$$->bval = true;
            	$$->ival = flag; //Indicates parameter
              // cout << "var_use : " << active_func_ptr->param_list[flag].type << " " << active_func_ptr->param_list[flag].peru << " " << active_func_ptr->param_list[flag].offset <<endl;
	        }
        	else
          {
            $$->type = ERR;
            $$->bval = false;
            $$->ival = -1;
            pretty_print_error("Sem mein galti: Arey ID declare kar k use karo bhai");
            arey_galti_hai_kya = true;
          }
	    }
	    else if ( id_rec->var_type != SIMPLE )
	    {
	        $$->type = ERR;
	        pretty_print_error("Sem mein galti: Array accessed as scalar.");
	        arey_galti_hai_kya = true;
	    }
	    else
	    {

	        $$->type = id_rec->type;
        	$$->bval = false;        	//Indicates normal variable
	        $$->ival = -1;
        	$$->label = $1;
	    }

	    //CodeGen
	    if (!arey_galti_hai_kya){
	        //Check in local variables -> if not found, check in param list -> if found, load param by offset
          if ( is_param )
            {
                stringstream s;//int ko string karne ka aur koi raasta nahe mila
                s << active_func_ptr->param_list[flag].offset;
                $$->dakshina += "lw $t0 " + s.str() + "($fp) \n";
            }
          else{
              $$->dakshina = load_mips_id( get_record($1) );
          }
	    }



	}
	| ID OPENSQUARE INTCONST CLOSESQUARE {

        //Semantic Analyses
        $$ = new attr();
        var_record* id_rec = get_record($1);
        if ( id_rec == NULL )
        {
            $$->type = ERR;
	        pretty_print_error("Sem mein galti: Arey ID declare kar k use karo bhai");
	        arey_galti_hai_kya = true;
        }
        else if ( id_rec->var_type != ARRAY )
	    {
	        $$->type = ERR;
	        pretty_print_error("Sem mein galti: Arey scalar ko dekh k user karo, array nahe h woh.");
	        arey_galti_hai_kya = true;
	    }
	    else
	    {
	        int iconst = atoi($3);
	        if(iconst < 0 || iconst >= id_rec->dim)
	        {
	            $$->type - ERR;
	            pretty_print_error("Sem mein galti: Array apne aukaat k bahar chala gya.");
	            arey_galti_hai_kya = true;
	        }
	        $$->type = id_rec->type;
	        $$->ival = iconst;
        	$$->label = $1;
	    }

        //CodeGen
        if (!arey_galti_hai_kya){
            $$->dakshina = load_mips_array( get_record($1),atoi($3));
        }


	}

supported_constant:
	INTCONST {

	    //Semantic Analyses
        $$ = new attr();
        $$->ival =  atoi($1);
        $$->type = INT;
        daram s = $1;
        $$->dakshina = "li $t0 " + s + "\n";

	    //CodeGen
	    //No codegen assoc with this production
    }
| CHARCONST {
	    //Semantic Analyses
        $$ = new attr();
        $$->cval =  *($1);
        $$->type = CHAR;

	    //CodeGen

        daram s = $1;
        $$->dakshina = "li $t0 \'" + s + "\' \n";



	}
	| BOOLCONST {
	    //Semantic Analyses
      $$ = new attr();
	    if( !strcmp($1, "true") ){
          $$->bval = 1;
          $$->dakshina = "li $t0 1\n";
      }

	    else{
            $$->bval = 0;
            $$->dakshina = "li $t0 0\n";
      }

	    $$->type = BOOL;

        //Semantic Analyses
	    //CodeGen



	}
	| OPENNEGATE INTCONST CLOSEPAREN {

	    //Semantic Analyses
      $$ = new attr();
	    $$->ival = atoi($2);
	    $$->ival = -($$->ival);
	    $$->type = INT;

	    //CodeGen
      $$->dakshina = "li $t0 -" + daram($2) + "\n" ;
	    //No codegen assoc with this production


	}
%%
int num_times = 2;
void pretty_print_error(const char* err_msg)
{
	arey_galti_hai_kya = true;
	cout<<"Line "<<yylineno<<": "<<err_msg<<endl;
}

void print_tree(node *cur, /* pointer to list of ints   */ vector<int>& ancestors, int parent)
{
	if(!cur) return;
	//for(int i = 0; i < ancestors.size(); i++) cout<<ancestors[i]<<" "; cout<<endl;
	for (int k = 0; k < num_times; k++)
	{
		for(int i = 0, j = 0; j < ancestors.size() && i < parent; i++)
		{
			if(i == ancestors[j]) j++, cout<<"|";
			else cout<<" ";
		}
		if(k!=num_times-1) cout<<endl;
	}
	if(ancestors.size()) cout<<"--+";
	cout<<cur->content;
	if(cur->type == VAL) cout<<" [`"<<cur->info<<"']";
	cout<<endl;

	ancestors.push_back(parent);
	print_tree(cur->child, ancestors, parent+4);
	ancestors.pop_back();
	print_tree(cur->sibling, ancestors, parent);
}

int main()
{
	vector<int> print_vec;
	yydebug = 0;
	yyparse();
	if(!arey_galti_hai_kya)	cout<<""<<endl;
	else cout<<"Compilation terminating with errors"<<endl;
}
