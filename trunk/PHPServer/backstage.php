<?php
// read configure file from dependns.ini
$Config = parse_ini_file("dependns.ini",true);

// check history database
// db link
if ( $Config['DataBase'] ) { 
	$DB_host = $Config['DataBase']['SQL_Server'];
	$DB_ID   = $Config['DataBase']['SQL_ID'];
	$DB_PWD  = $Config['DataBase']['SQL_PWD'];


} else {
	$DB_host = "localhost";
	$DB_ID	 = "dependns";
	$DB_PWD	 = "dependns@833";
}

$odbc_id = odbc_connect("dependns",$DB_ID,$DB_PWD);
if (!$odbc_id){
	print "<h1>Data Base Down!</h1>";
}

$SQL = "SELECT domain_id.domain_name FROM domain_id, WhiteList WHERE domain_id.id = WhiteList.domain_id";
$result = odbc_exec($SQL,$odbc_id);

while ( $row = odbc_fetch_array($result)){
	print "<p>$row['domain_id']</p>";
}

?>
