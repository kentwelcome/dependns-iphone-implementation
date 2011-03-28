<?php
$DB_host = "localhost";
$DB_ID   = "dependns";
$DB_PWD  = "dependns@833";

if ( $_SERVER['argc'] == 1 ){
	$question = $_SERVER['argv'][1];
} else {
	$question = "www.google.com";
}

$link = odbc_connect("dependns",$DB_ID,$DB_PWD);

?>
