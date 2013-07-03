%{


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
//#include <assert.h>
#include <json/json.h>

struct list_el {
	char* content;
	struct list_el* next;
};

typedef struct list_el item;

item* table_list = NULL;
item* field_list = NULL;
item* variable_list = NULL;
item* condition_list = NULL;
item* value_field_list = NULL;
item* attr_field_list = NULL;
item* create_table_data_struct = NULL ;
item* numbers_field = NULL ;
static FILE* file_sql ;
//item* create_table_fields = NULL ;
//item* create_table_values = NULL ;

char* insert_tablename;

int create_a_table( item* tables, item* fields, item* numbers_field ) ;


void erase_list(item* l) {	
	while(l != NULL) {
		item* current = l->next;
		free(l);
		l = current;
	}
}

item* push_list(char* var, item* l) {
	item* tmpl = (item*)malloc(sizeof(item));
	tmpl->content = var;
	tmpl->next = l;
	return tmpl;
}

item* reverse_list(item* l) {
    item* tmpl = NULL;
    item* itl = l;
    while (itl != NULL) {
        tmpl = push_list(itl->content, tmpl);
        itl = itl->next;
    }
    erase_list(l);
    return tmpl;
}

void reinit() {
	erase_list(table_list);
	erase_list(field_list);
	erase_list(condition_list);
	erase_list(variable_list);
	erase_list(value_field_list);
	erase_list(attr_field_list);

    /*** create table list handling ***/
	erase_list(create_table_data_struct);
    create_table_data_struct = NULL ;
	erase_list(numbers_field);
    numbers_field = NULL ;

	table_list = NULL;
	field_list = NULL;
	variable_list = NULL;
	condition_list = NULL;
	value_field_list = NULL;
	attr_field_list = NULL;
}

char* print_list(item* l) {
    char* res = NULL;
    do {
        if (res == NULL) {
        if(l == NULL) return "";
            res = (char*) malloc(sizeof(char)*2000);
            res[0] = '\0';
            res = strcat(res, l->content);
        }
        else{
            res = strcat(res, " ");
            res = strcat(res, l->content);
            }
        l = l->next;			
    } while(l != NULL);
    return res;
}

void print_select() {
	char* field_names = print_list(field_list);
	char* table_names = print_list(table_list);
	char* conditions_names = print_list(condition_list);
	printf("Select in %s\nFields:%s\nConditions:%s\n", table_names, field_names, conditions_names);
}

void print_insert(char* tablename,char* field_names,char* variable_names) {
	printf("Insert in %s\nFields:%s\nData:%s\n",tablename,field_names,variable_names);
}
void print_update(char* tablename,char* field_names,char* variable_names){
	printf("Insert in %s\nFields:%s\nData:%s\n",tablename,field_names,variable_names);
}

/*print table properties*/
void print_create_table2( ){
    char* field_names = print_list(field_list);
    char* table_names = print_list(table_list);
    char* type_struct = print_list(create_table_data_struct);
    char* types_limits = print_list( numbers_field ) ; 
	printf("Creating table %s\nFields:%s\nData structures:%s\nData limits:%s\n", table_names, 
           field_names, type_struct, types_limits);

}

/** create and json table object **/
int create_a_table( item* tables, item* fields, item* datas_struct ){
    json_object  * jobj         = json_object_new_object() ;
    json_object * champsproper = json_object_new_object() ;
    json_object * valuesArray  = json_object_new_array() ;
    json_object * jobj2         = json_object_new_object() ;

    while( fields != NULL ){
      json_object_object_add( champsproper, fields -> content,
                              json_object_new_string( datas_struct -> content ) ) ;
      fields = fields -> next ;
      datas_struct = datas_struct -> next ;
      //if ( fields == NULL )
       //break ;
    }

    json_object_object_add( jobj2 , "description"     , champsproper ) ;
    json_object_object_add( jobj2 , "datas"           , valuesArray  ) ;
    json_object_object_add( jobj  , tables -> content , jobj2        ) ;
    long size  = strlen( json_object_to_json_string( jobj ) ) ;
    printf( " le json vaut: %s\n", json_object_to_json_string( jobj ) ) ;
    fseek( file_sql, 0, SEEK_SET ) ;
    int res = fwrite(  json_object_to_json_string( jobj ), sizeof( char ) , size, file_sql ) ; 
    //assert( res == 4 ) ;
    printf( " char written %ld\n", res ) ;
    //json_objet * tabName = json_object_new_string(table_names) ;
    return 0 ;

}


/*
void print_create_table( ){
    char* field_names = print_list(create_table_fields);
    char* table_names = print_list(create_table_name);
	char* conditions_names = print_list(create_table_values);
	printf("Creating table %s\nFields:%s\nData structures:%s\n", table_names, field_names, conditions_names);
}
*/

%} 

%union { 
	double val;
	char* var;
    int nomb;
}

%token  <val> VALEUR
%token  <var> VARIABLE
%token  <nomb> NOMBRE
%token SELECT FROM COMMA SEMICOLON WHERE EQUAL AND OR
%token INSERT INTO PARENTHLEFT PARENTHRIGHT VALUES
%token UPDATE SET
%token DELETE
%token CREATE TABLE VARCHAR INTEGER CHAR PRIMARY KEY
%token EXIT

%start SENTENCES;
%%

SENTENCES:
	  SENTENCES SENTENCE SEMICOLON
            {
                //printf("Before reinit\n");
                reinit();
                //printf("After reinit\n");
            }
	| SENTENCE SEMICOLON
            {
                //printf("Before reinit\n");
                reinit();
                //printf("After reinit\n");
            }
	;

SENTENCE:
	  SELECT_SENTENCE
            {
                field_list = reverse_list(field_list);
                table_list = reverse_list(table_list);
                condition_list = reverse_list(condition_list);
                print_select();
            }
	   | INSERT_SENTENCE{
						field_list = reverse_list(field_list);
						variable_list = reverse_list(variable_list);
						print_insert(insert_tablename,print_list(field_list),print_list(variable_list));
		}
		| UPDATE_SENTENCE{
				value_field_list = reverse_list(value_field_list);
				attr_field_list = reverse_list(attr_field_list);
				print_update(insert_tablename,print_list(attr_field_list),print_list(value_field_list)) ;
		}
		| DELETE_SENTENCE{
						field_list = reverse_list(field_list);
						table_list = reverse_list(table_list);
						condition_list = reverse_list(condition_list);
						print_select();
		}
		| CREATE_SENTENCE{
                        field_list = reverse_list(field_list);
                        table_list = reverse_list(table_list);
                        create_table_data_struct = reverse_list(create_table_data_struct);
                        numbers_field = reverse_list(numbers_field);
                        print_create_table2() ;
                        create_a_table( table_list, field_list, create_table_data_struct );
		
		}
        | EXIT_SENTENCE{
        };

SELECT_SENTENCE:
               SELECT FIELD_LIST FROM TABLE_LIST
               {
               }
               | SELECT FIELD_LIST FROM TABLE_LIST WHERE CONDITIONS
               {
               };

FIELD_LIST:
          FIELD_LIST COMMA VARIABLE 	
          { 
                //printf("Before field list\n");
                field_list = push_list($3, field_list);
                //printf("After field list: %s\n", $3);
          }	  
          | VARIABLE
          { 
                //printf("Before field variable\n");
                field_list = push_list($1, field_list);
                //printf("After field variable: %s\n", $1);
          };

TABLE_LIST:
          TABLE_LIST COMMA VARIABLE
          {
            //printf("Before table list\n");
            table_list = push_list($3, table_list);
            //printf("After table list: %s\n", $3);
          }
	| VARIABLE
            {
                //printf("Before table variable\n");
                table_list = push_list($1, table_list);
                //printf("After table variable: %s\n", $1);
            }
	;
	
VARIABLE_LIST:
             VARIABLE_LIST COMMA VARIABLE
             { 
                 variable_list = push_list($3, variable_list);
             }	  
             | VARIABLE
             { 
                  variable_list = push_list($1, variable_list);
             };

CONDITION:
         VARIABLE EQUAL VARIABLE{
         //char buffer[2000];
         //sprintf(buffer,"%s=%s",$1,$3);
         condition_list = push_list($1,condition_list);
         }
         ;

CONDITIONS:
          CONDITIONS AND CONDITION{
          }
          |CONDITIONS OR CONDITION{
          }
          | CONDITION{
          };

INSERT_SENTENCE:
               INSERT INTO VARIABLE PARENTHLEFT FIELD_LIST PARENTHRIGHT VALUES PARENTHLEFT VARIABLE_LIST PARENTHRIGHT{
               insert_tablename = $3;
               };
	
UPDATE_SENTENCE:
               UPDATE VARIABLE SET ATTRIBUTIONS WHERE CONDITIONS{
               insert_tablename = $2;
               };

ATTRIBUTIONS:
            ATTRIBUTIONS COMMA VARIABLE EQUAL VARIABLE 	
            { 
                attr_field_list = push_list($3, attr_field_list);
                value_field_list = push_list($5, value_field_list);
            }	  
            |VARIABLE EQUAL VARIABLE
            { 
                attr_field_list = push_list($1, attr_field_list);
                value_field_list = push_list($3, value_field_list);
            };
	
DELETE_SENTENCE:
               DELETE FROM TABLE_LIST WHERE CONDITIONS{
                 //table_list = push_list($3, table_list ) ;
               };

CREATE_SENTENCE:
               CREATE TABLE VARIABLE PARENTHLEFT CREATE_LIST PARENTHRIGHT{
                table_list = push_list($3, table_list) ;
               };

CREATE_LIST:
           CREATE_LIST COMMA CREATE_FIELD{
           }
           | CREATE_FIELD{
           };

CREATE_FIELD:
            VARIABLE TYPE PARENTHLEFT NOMBRE PARENTHRIGHT{
                //create_table_data_struct = push($1,create_table_data_struct) ;
                field_list = push_list($1, field_list) ;
                // handling the limits which here is and integer
                char tmpStr[20] ;
                sprintf( tmpStr, "%d", $4 ) ;
                numbers_field = push_list(tmpStr , numbers_field ) ;

            }
            | VARIABLE TYPE{
                field_list = push_list($1, field_list) ;
            
            } 
            | PRIMARY KEY PARENTHLEFT VARIABLE PARENTHRIGHT{
                field_list = push_list($4, field_list) ;
            };

TYPE: 
    VARCHAR{
        create_table_data_struct  = push_list( (char * ) "varchar", create_table_data_struct ) ;
    } 
    | INTEGER{
        create_table_data_struct  = push_list( (char * ) "integer", create_table_data_struct ) ;
             } 
    | CHAR{
        create_table_data_struct  = push_list( ( char * ) "char", create_table_data_struct ) ;
    }; 

EXIT_SENTENCE:
             EXIT{
             return 0 ;
             };

%%

int yyerror(char *s) {
  printf("%s\n",s);
  yyparse();
  //return 1;
}

int main(int argc , char** argv) {

  file_sql = fopen("./database.json", "w+b" ) ;
  if ( file_sql == NULL ) 
   return 0 ;

  //assert(file_sql != NULL) ;
  yyparse();
  fclose( file_sql ) ;
  return 0;

}
