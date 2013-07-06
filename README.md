
1 - make clean
2 - make 
3 - ./sql_parser.exe
4 - entrez la commande
    example :
    create table NameTab ( champs1 integer, champs2 VARCHAR(30) ) ;
    ou
    insert into tabName ( champs1, champs2 ) values ( toto, tata ) ;
    ou si table creer

    5- tapez exit ou quit pour quitte 
    6- creation de table dans le json pris en charge

    Vous pouvez copier-coller les commandes suivantes 
    en selectionnant tout en effet vous pouvez entrez plusieurs 
    du moment qu'il y a un ";" a la fin de chaque commande 
    commandes a la suite sinon un a un ;) enjoy:
    /** good ****/
    create table md2 ( nom char, prenom char, address char, telephone char ) ; 
    insert into md2 ( nom, prenom ) values ( poissonn, mojs ) ;
    insert into md2 ( nom, prenom, address, telephone ) values ( coulibaly, mamadou, paris, fixe );
    select nom, prenom from md2;
    select nom, prenom from md2 where nom = poissonn ;
    select nom, prenom, telephone from md2 where nom = coulibaly OR  prenom = mojs  ;
    UPDATE md2 SET nom=poissonnet WHERE nom = poissonn ;
    DELETE FROM md2 WHERE  nom = poissonnet ;
