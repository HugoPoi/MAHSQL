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
json_object* jroot ;
//item* create_table_fields = NULL ;
//item* create_table_values = NULL ;

char* insert_tablename;

int is_table_exist( char* tab_name ) ;
json_object* get_description( json_object* table_in ) ;
json_object* get_datas_array( json_object* table_in ) ;
//void json_object_object_add2(struct json_object* jso, 
//const char *key,struct json_object *val);
int set_champs( json_object* dataArr, char* fields, char* values ) ;
int set_empty_line( json_object* table_in ) ;
int create_a_table( item* tables, item* fields, item* numbers_field ) ;
json_object * get_table_idx( char * table_name ) ;
int insert_into_table(item* table_in, item* field_list_in, item* variable_list_in);


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




/******** watch out donot touch ****
void json_object_object_add2(struct json_object* jso, const char *key,struct json_object *val)
{
// We lookup the entry and replace the value, rather than just deleting
// and re-adding it, so the existing key remains valid.
    json_object *existing_value = NULL;
    struct lh_entry *existing_entry;
     existing_entry = lh_table_lookup_entry(jso->o.c_object, (void*)key);
     if (!existing_entry)
     {
        lh_table_insert(jso->o.c_object, strdup(key), val);
        return;
     }
     existing_value = (void *)existing_entry->v;
     if (existing_value)
        json_object_put(existing_value);
    existing_entry->v = val;
}

******** watch out donot touch ****/



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
int insert_into_table(item* table_in, item* field_list_in, item* variable_list_in){
    json_object * jtable = NULL ; 
    json_object * jarray = NULL ; 

    /*** get table requested **/
    jtable = get_table_idx( table_in -> content ) ;  
    if ( jtable == NULL ){
        printf ( " failed to find the table \n" ) ;
        return 1 ;
    }
    /*** get array index **/
    jarray = get_datas_array( jtable ) ;
    if ( jarray == NULL ){
        printf ( " failed to find the datas \n" ) ;
        return 1 ;
    }
    while ( field_list_in ){
         set_champs( jarray,
                    field_list_in -> content,
                    variable_list_in -> content );
         field_list_in     = field_list_in -> next ;
         variable_list_in  = variable_list_in -> next ;
    } 

    printf( "the table is:%s\n", json_object_to_json_string( jtable ) );
    set_empty_line( jtable ) ;

    /*** save in the file ****/
    file_sql = fopen("./database.json", "r+b" ) ;
    if ( file_sql == NULL ){ 
        printf( " file problem \n") ;
        return 1 ;
    }
    long size  = strlen( json_object_to_json_string( jroot ) );
    fseek( file_sql, 0, SEEK_SET ) ;
    long res = fwrite(  json_object_to_json_string( jroot ), 
                        sizeof( char ) , size, file_sql ) ; 
    printf( " char written %ld\n", res ) ;
    fclose( file_sql ) ;

    return 0 ;
}

json_object * get_table_idx( char * table_name ) {
     json_object_object_foreach( jroot, key, val ){
        /** to be replace by strcasecmp **/
        if ( 0 ==  strcmp( table_name, key ) ){
            return val;
        }
    }
    return NULL ;
}
/*** add empty_line in data array ****/
int set_empty_line( json_object* table_in ){
    json_object * array = get_datas_array( table_in ) ;
    json_object * desc  = get_description( table_in ) ;
    if ( (!array) || (!desc) ){
        printf ( " problem de recup de donnees et-ou description \n" ) ;
        return 1 ;
    }
    json_object_array_add ( array, desc  ) ;
    return 0 ;
}

/*** setter les champs du json et oui je passe en français lol ***/
int set_champs( json_object* dataArr, char* fields, char* values ) {
    char * field[100] ;
    char * value[100] ;
    field[0] = '\0' ;
    value[0] = '\0' ;
    strcpy( field, fields ) ; 
    strcpy( value, values ) ;
    int array_length = json_object_array_length( dataArr ) ;
    json_object * line = json_object_array_get_idx( dataArr,
                                (array_length-1));
    json_object_object_foreach( line, key, val ){
        if ( strcmp( key, field ) == 0 ){
            const char * tmpVal  = json_object_to_json_string( val ) ;
            if ( !strcmp("integer", tmpVal) ){
                int num  = atoi( value ) ;
                if( !num && strcmp( "0", value ) ) {
                    printf ( " integer was expected for value " ) ;
                }
                else{
                    json_object_object_add( line, key, 
                                json_object_new_string( value ) );
                }
            } 
            else{
                //json_object_object_add( val, key, 
                printf( "val %s\n", json_object_to_json_string(val)  ) ;
                json_object_object_add( line, key, json_object_new_string(value) ) ;
                            
            }
        }
    }

    return 0 ;
}

/*** get description structuration ***/
json_object* get_description( json_object* table_in ){
    json_object_object_foreach( table_in, key, val ){
        /** to be replace by strcasecmp **/
        if ( 0 ==  strcmp( "description", key ) ){
            return val;
        }
    }
    return NULL ;
}

/*** get data array from some table ***/
json_object* get_datas_array( json_object* table_in ){
    json_object_object_foreach( table_in, key, val ){
        /** to be replace by strcasecmp **/
        if ( 0 ==  strcmp( "datas", key ) ){
            if ( json_type_array == json_object_get_type( val ) ){
            return val;
            }else{
                printf( "not an array !!!!!!!!!!!!!\n" ) ;
            }
        }
    }
    return NULL ;
}

/** create and json table object **/
int create_a_table( item* tables, item* fields, item* datas_struct ){
    
    /** check if the table already exist **/
    if ( is_table_exist( tables -> content ) ){
        printf( "Sorry this table already exist!\n" ) ;
        return 0 ;
    }
    file_sql = fopen("./database.json", "r+b" ) ;
    if ( file_sql == NULL ){ 
        printf( " file problem \n") ;
        return 1 ;
    }

    json_object * champsproper = json_object_new_object() ;
    json_object * valuesArray  = json_object_new_array() ;
    json_object * jobj2        = json_object_new_object() ;

    while( fields != NULL ){
      json_object_object_add( champsproper, fields -> content,
                              json_object_new_string( datas_struct -> content ) ) ;
      fields = fields -> next ;
      datas_struct = datas_struct -> next ;

    }

    json_object_object_add(jobj2, "description", champsproper);
    json_object_array_add(valuesArray, champsproper ) ; 
    json_object_object_add(jobj2, "datas", valuesArray);
    json_object_object_add(jroot, tables -> content , jobj2);
    long size  = strlen( json_object_to_json_string( jroot ) );
    printf( " le json vaut: %s\n", 
          json_object_to_json_string( jroot ) ) ;
    fseek( file_sql, 0, SEEK_SET ) ;
    long res = fwrite(  json_object_to_json_string( jroot ), 
                        sizeof( char ) , size, file_sql ) ; 
    printf( " char written %ld\n", res ) ;
    fclose( file_sql ) ;
    return 0 ;
}

 int is_table_exist( char* tab_name ){
    json_object_object_foreach( jroot, key, val ){
        /** to be replace by strcasecmp **/
        if ( 0 ==  strcmp( tab_name, key ) ){
            return 1 ;
        }
    }
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
                        table_list = reverse_list(table_list);
						field_list = reverse_list(field_list);
						variable_list = reverse_list(variable_list);
						print_insert(print_list(table_list),print_list(field_list),
                                     print_list(variable_list));

                        insert_into_table( table_list, 
                        field_list, variable_list );
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
                table_list = push_list($3, table_list) ;
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

    long file_size = 0  ;
    file_sql = fopen("./database.json", "r+b" ) ;
    if ( file_sql == NULL ){ 
        file_sql = fopen("./database.json", "w+b" ) ;
        if ( file_sql == NULL ){
          return 0 ;
        }
    }

    /*** check if the file is empty 
    ****and return at the beginning ***/
    fseek(file_sql, 0, SEEK_END) ;
    file_size = ftell(file_sql) ;
    fseek(file_sql, 0, SEEK_SET) ;
    if (file_size == 0){
        printf( "the database is empty\n" ) ;
        jroot = json_object_new_object() ;
    }
    else{
      char * tmp_string = (char *) malloc( sizeof(char) * (file_size + 1) ) ;
        /*** get main json object ***/
        fread(tmp_string, sizeof(char), file_size, file_sql) ;
        jroot = json_tokener_parse( tmp_string ) ;
    }
    fclose( file_sql ) ;
    yyparse();
    return 0;

}
