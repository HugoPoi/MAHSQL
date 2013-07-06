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
item* and_or_list = NULL;
item* resultSet = NULL ;
item* value_field_list = NULL;
item* attr_field_list = NULL;
item* create_table_data_struct = NULL ;
item* numbers_field = NULL ;
static FILE* file_sql ;
json_object* jroot ;

char* insert_tablename;
int reiinit_json() ;
int is_table_exist( char* tab_name ) ;
int del_idx_from_array( json_object* dataArr, int idx ) ;
json_object* get_description( json_object* table_in ) ;
int no_select_condition(json_object* dataArr, item** field_listC) ;
json_object* get_datas_array( json_object* table_in ) ;
int check_cond3( json_object* dataArr, char* field , char* value );
int check_cond( json_object* dataArr, item** field_listC, char* field, char* value ) ;
int check_cond2( json_object* dataArr, item** field_listC, item** attr_in, char* field , char* value );
int get_champs( json_object* dataArr, int row, char* champs ) ;
int set_champs( json_object* dataArr, char* field, char* value ) ;
int set_champs_update( json_object* dataArr,int iter, char* field, char* value ) ;
int set_empty_line( json_object* table_in ) ;
int create_a_table( item* tables, item* fields, item* numbers_field ) ;
json_object * get_table_idx( char * table_name ) ;
int insert_into_table(item* table_in, item* field_list_in, item* variable_list_in);
int select_from_table(item* table_in, item* field_in, item* condition_in, item* and_or_list_in ) ;



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
	erase_list(and_or_list);
	erase_list(variable_list);
	erase_list(value_field_list);
	erase_list(attr_field_list);
	erase_list(resultSet);
	erase_list(create_table_data_struct);
	erase_list(numbers_field);

    create_table_data_struct = NULL ;
    numbers_field = NULL ;
	table_list = NULL;
	field_list = NULL;
    and_or_list = NULL ;
	variable_list = NULL;
	condition_list = NULL;
	value_field_list = NULL;
	attr_field_list = NULL;
    resultSet = NULL;
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
	printf("Select in:%s\nFields:%s\nConditions:%s\n", table_names, field_names, conditions_names);
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

/************************************** insert handling *******************************************/
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
         int set = set_champs( jarray,
                    field_list_in -> content,
                    variable_list_in -> content );
         field_list_in     = field_list_in -> next ;
         variable_list_in  = variable_list_in -> next ;
         if ( set || ( field_list_in && !variable_list_in ) || ( variable_list_in && !field_list_in ) ) {
            printf( " error detected check your syntaxe \n" ) ;
            return 1 ;
         }
    } 

    printf( "\nthe table after insert is:\n%s\n"
    , json_object_to_json_string( jtable ) );

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
    reiinit_json() ;
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
/****** set champs for the update *******/
int set_champs_update( json_object* dataArr,int iter, char* field, char* value ){
    //int array_length = json_object_array_length( dataArr ) ;
    json_object * line = json_object_array_get_idx( dataArr, iter);

    json_object_object_foreach( line, key, val ){
        if ( strcmp( key, field ) == 0 ){
            const char * tmpVal  = json_object_to_json_string( val ) ;
            if ( strstr("integer", tmpVal) ){
                int num  = atoi( value ) ;
                if( !num && strcmp( "0", value ) ) {
                    printf ( " integer was expected for value " ) ;
                    return 1 ;
                }
                else{
                    json_object_object_add( line, key, 
                                json_object_new_string( value ) );
                                return 0 ;
                }
            } 
            else{
                json_object_object_add( line, key, json_object_new_string(value) ) ;
                return 0 ;
            }
        }
    }

    return 1 ;
}

/*** setter les champs du json et oui je passe en français lol ***/
int set_champs( json_object* dataArr, char* field, char* value ) {
    int array_length = json_object_array_length( dataArr ) ;
    json_object * line = json_object_array_get_idx( dataArr,
                                (array_length-1));
    json_object_object_foreach( line, key, val ){
        if ( strcmp( key, field ) == 0 ){
            const char * tmpVal  = json_object_to_json_string( val ) ;
            if ( strstr("integer", tmpVal) ){
                int num  = atoi( value ) ;
                if( !num && strcmp( "0", value ) ) {
                    printf ( " integer was expected for value " ) ;
                    return 1 ;
                }
                else{
                    json_object_object_add( line, key, 
                                json_object_new_string( value ) );
                }
            } 
            else{
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

/**** check match between command field and cond ****/
int check_fiel_cond_match( item ** fields, char * cond_field ) {
    item* tmplist = *(fields) ;
    while( tmplist ){
        if ( strcmp( tmplist-> content , cond_field ) == 0 ){
            return 1;
        }
        tmplist = tmplist -> next ;
    } ;
    return 0 ;

}


/*** check conditions ****/
int check_cond( json_object* dataArr,item** field_listC, char* field, char* value ){
    int array_length = json_object_array_length( dataArr ) ;
    int iterArr = 0 ;
    int check = check_fiel_cond_match( field_listC, field ) ; 
    if( !check ){
        printf( " field not valid\n" ) ;
        return 1 ;
    };
    for( iterArr = 0; iterArr < array_length; iterArr++){ 

    json_object * line = json_object_array_get_idx( dataArr, iterArr);
        json_object_object_foreach( line, key, val ){
         item* tmplist = *(field_listC)  ;
            if ( strcmp( key, field )  == 0 ){
                const char * tmp = json_object_to_json_string(
                            json_object_new_string( value ) ) ;
                const char * tmpVal = json_object_to_json_string( val ) ;
                if(strcmp( tmp, tmpVal ) == 0 ){
                    resultSet = push_list( "\nnew line match:\n", resultSet );
                    while( tmplist ){
                        int res = get_champs( dataArr, iterArr
                                    , tmplist -> content ) ;
                        if( res ){
                            printf( " field not valid\n" ) ;
                            return 1 ;
                        }
                        tmplist = tmplist -> next ;
                    }
                } 
            }
        }
    }
    return 0;

}

/******* check condition 2 for the update *********/
int check_cond2( json_object* dataArr, item** field_listC, item** attr_in, char* field , char* value ){
    int array_length = json_object_array_length( dataArr ) ;
    int iterArr = 0 ;

    for( iterArr = 0; iterArr < array_length; iterArr++){ 

    json_object * line = json_object_array_get_idx( dataArr, iterArr);
        json_object_object_foreach( line, key, val ){
         item* tmplist = *(field_listC)  ;
         item* tmpattr = *(attr_in)  ;
            if ( strcmp( key, field )  == 0 ){
                const char * tmp = json_object_to_json_string(
                            json_object_new_string( value ) ) ;
                const char * tmpVal = json_object_to_json_string( val ) ;
                if(strcmp( tmp, tmpVal ) == 0 ){
                    resultSet = push_list( "\nnew line match:\n", resultSet );
                    while( tmplist ){
                        int res = set_champs_update( dataArr, iterArr
                                    , tmplist -> content, tmpattr -> content  ) ;

                        if( res ){
                            printf( " field not valid\n" ) ;
                            return 1 ;
                        }
                        tmplist = tmplist -> next ;
                        tmpattr = tmpattr -> next ;
                    }
                } 
            }
        }
    }
    return 0;

}


/**** condition check 3 for delete *****/
int check_cond3( json_object* dataArr, char* field , char* value ){
    int array_length = json_object_array_length( dataArr ) ;
    int iterArr = 0 ;

    for( iterArr = 0; iterArr < array_length; iterArr++){ 

    json_object * line = json_object_array_get_idx( dataArr, iterArr);
        json_object_object_foreach( line, key, val ){
            if ( strcmp( key, field )  == 0 ){
                const char * tmp = json_object_to_json_string(
                            json_object_new_string( value ) ) ;
                const char * tmpVal = json_object_to_json_string( val ) ;
                if(strcmp( tmp, tmpVal ) == 0 ){
                        int res = del_idx_from_array( dataArr, iterArr ) ;
                        if( res ){
                            printf( " field not valid\n" ) ;
                            return 1 ;
                    }
                } 
            }
        }
    }
    return 0;

}

int no_select_condition(json_object* dataArr, item** field_listC){

            int array_length = json_object_array_length( dataArr ) ;
            int iterArr = 0 ;
            for( iterArr = 0; iterArr < array_length-1 ; iterArr++){ 
                item* tmplist = *(field_listC)  ;
                resultSet = push_list( "\nnew line match:\n", resultSet );
                    while( tmplist ){
                        int res = get_champs( dataArr, iterArr
                                    , tmplist -> content ) ;
                        if( res ){
                            printf( " field not valid\n" ) ;
                            return 1 ;
                        }
                        tmplist = tmplist -> next ;
                    }


            }
            return 0;

}
/**get certains field from some table ******/
int get_champs( json_object* dataArr, int row, char* champs ) {
            
        json_object * line = json_object_array_get_idx( dataArr, row);
        json_object_object_foreach( line, key, val ){
            if ( strcmp( key, champs )  == 0 ){
                resultSet = push_list( (char *) json_object_to_json_string( val ) 
                                , resultSet ) ;
                        return 0 ;
                } 
        }
        
        return 1 ;
}



/********************update table ****************************************************/
int update_table( item* table_in, item* field_in, item* attr_in, item* condition_in ) {
        
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
     while ( condition_in ){
        if ( condition_in -> content  && condition_in -> next ){
            char * cond_field = condition_in -> content ;
            condition_in = condition_in -> next ;
            char * cond_val   = condition_in -> content ;
            int row = check_cond2( jarray, &field_in, &attr_in, cond_field , cond_val );
            if ( row ){
                printf ( " syntaxe error updata check fields and conds\n" ) ;
                return 1 ;

            }
        }
        condition_in  = condition_in -> next ;
     }

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
    reiinit_json() ;
    printf( " \nafter update table is: \n%s\n"
        ,json_object_to_json_string( jroot )  ) ;

    return 0 ;
}

/******************************************SELECT handling ************************************************/
int select_from_table(item* table_in, item* field_in, item* condition_in, item* and_or_list_in ) {
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
   if( condition_in ){ 
     while ( condition_in ){
        if ( condition_in -> content  && condition_in -> next ){
            char * cond_field = condition_in -> content ;
            condition_in = condition_in -> next ;
            char * cond_val   = condition_in -> content ;
            int row = check_cond( jarray, &field_in, cond_field , cond_val );
            if ( row ){
                printf ( " syntaxe error check fields and conds\n" ) ;
                return 1 ;

            }
        }
        condition_in  = condition_in -> next ;
     }
    }else{
            //printf ( " no cond\n" ) ;
            int row =  no_select_condition(jarray, &field_in );
            if ( row ){
                printf ( " syntaxe error check fields and conds\n" ) ;
                return 1 ;
            }


    }
    resultSet = reverse_list( resultSet ) ;
    printf( "\nresultat du select:%s\n", print_list( resultSet ) ) ;
    return 0 ; 
}

/****** delete object at the index from array ******/
int del_idx_from_array( json_object* dataArr, int idx ) {

    json_object * line = json_object_array_get_idx( dataArr, idx);
    json_object_array_put_idx( dataArr, idx,json_object_new_object()) ;
    return 0 ;
}

/****** delete from table *********************************************************************************/
int delete_from_table( item* table_in, item* condition_in ){

        
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
     while ( condition_in ){
        if ( condition_in -> content  && condition_in -> next ){
            char * cond_field = condition_in -> content ;
            condition_in = condition_in -> next ;
            char * cond_val   = condition_in -> content ;
            int row = check_cond3( jarray, cond_field , cond_val );
            if ( row ){
                printf ( " syntaxe error delete check fields and conds\n" ) ;
                return 1 ;

            }
        }
        condition_in  = condition_in -> next ;
     }

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
    reiinit_json() ;
    printf( " \nafter delete table is: \n%s\n"
        ,json_object_to_json_string( jroot )  ) ;

 

return 0;
}
/**********************************create and json table object ******************************************/
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
    printf( "\n\nla base apres ajout de table vaut: \n%s\n", 
          json_object_to_json_string( jroot ) ) ;
    fseek( file_sql, 0, SEEK_SET ) ;
    fwrite(  json_object_to_json_string( jroot ), 
                        sizeof( char ) , size, file_sql ) ; 
    fclose( file_sql ) ;
    reiinit_json() ;
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
                and_or_list = reverse_list(and_or_list ) ;
               // print_select();
                select_from_table( table_list, field_list, condition_list, and_or_list ) ;
            }
	   | INSERT_SENTENCE{
                        table_list = reverse_list(table_list);
						field_list = reverse_list(field_list);
						variable_list = reverse_list(variable_list);
						//print_insert(print_list(table_list)
                        //,print_list(field_list),print_list(variable_list));
                        insert_into_table( table_list, 
                        field_list, variable_list );
		}
		| UPDATE_SENTENCE{
                table_list = reverse_list(table_list);
				field_list = reverse_list(field_list);
                condition_list = reverse_list(condition_list);
				attr_field_list = reverse_list(attr_field_list);
				//print_update(insert_tablename,print_list(attr_field_list),print_list(value_field_list)) ;
                update_table( table_list, field_list, attr_field_list, condition_list ) ;
		}
		| DELETE_SENTENCE{
						//field_list = reverse_list(field_list);
						table_list = reverse_list(table_list);
						condition_list = reverse_list(condition_list);
						//print_select();
                        delete_from_table( table_list, condition_list ) ;
		}
		| CREATE_SENTENCE{
                        field_list = reverse_list(field_list);
                        table_list = reverse_list(table_list);
                        create_table_data_struct = reverse_list(create_table_data_struct);
                        numbers_field = reverse_list(numbers_field);
                        //print_create_table2() ;
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
             }
             |VARIABLE_LIST COMMA NOMBRE{
                  char tmpStr[20] ;
                  sprintf( tmpStr, "%d", $3 ) ;
                  variable_list = push_list(( char*) tmpStr, variable_list);
             }
             |NOMBRE{
                  char tmpStr[20] ;
                  sprintf( tmpStr, "%d", $1 ) ;
                  variable_list = push_list(( char*) tmpStr, variable_list);
             };

CONDITION:
         VARIABLE EQUAL VARIABLE{
         //char buffer[2000];
         //sprintf(buffer,"%s=%s",$1,$3);
         condition_list = push_list($1,condition_list);
         condition_list = push_list($3,condition_list);
         }
         ;

CONDITIONS:
          CONDITIONS AND CONDITION{
            and_or_list = push_list("and", and_or_list );
          }
          |CONDITIONS OR CONDITION{
            and_or_list = push_list("or", and_or_list );
          }
          | CONDITION{
          };

INSERT_SENTENCE:
               INSERT INTO VARIABLE PARENTHLEFT FIELD_LIST PARENTHRIGHT VALUES PARENTHLEFT VARIABLE_LIST PARENTHRIGHT{
                table_list = push_list($3, table_list) ;
               };
	
UPDATE_SENTENCE:
               UPDATE VARIABLE SET ATTRIBUTIONS WHERE CONDITIONS{
                table_list = push_list($2, table_list) ;
               };

ATTRIBUTIONS:
            ATTRIBUTIONS COMMA VARIABLE EQUAL VARIABLE 	
            { 
                field_list = push_list($3, field_list);
                attr_field_list = push_list($5, attr_field_list);
            }	  
            |VARIABLE EQUAL VARIABLE
            { 
                field_list = push_list($1, field_list);
                attr_field_list = push_list($3, attr_field_list);
            };
	
DELETE_SENTENCE:
               DELETE FROM VARIABLE WHERE CONDITIONS{
                 table_list = push_list($3, table_list ) ;
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
  return 1 ;
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
        free( tmp_string ) ;
    }
    fclose( file_sql ) ;
    yyparse();
    return 0;

}

int reiinit_json(){
    json_object_put(jroot);
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
    long file_size = ftell(file_sql) ;
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

    return 0;
}
