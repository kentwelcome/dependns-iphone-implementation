<?php
$DB_host = "localhost";
$DB_ID   = "dependns";
$DB_PWD  = "dependns@833";
$question = "www.cs.nthu.edu.tw";
$link = odbc_connect("dependns",$DB_ID,$DB_PWD);
	$question = $_SERVER['argv'][1];

$sql_query = "SELECT id FROM domain_id WHERE domain_name = '".$question."';";
$result = odbc_exec($link,$sql_query);
$row = odbc_fetch_array($result);
$id = $row['id'];
$sql_query = "select ip , count(ip) from domain_$id group by ip;";
$result = odbc_exec($link,$sql_query);
$row = odbc_fetch_array($result);
print "odbc:\t".$row['ip']."\t".$row['count(ip)']."\n";
/*if ( odbc_fetch_row($result) ){
	$row = odbc_result($result,1);
	$row2 = odbc_result($result,2);
	print "odbc:\t".$row."\t".$row2."\n";
}*/
/*
$row = odbc_fetch_array($result);
print "odbc:\t".$row['id']."\n";
if ( $row['id'] == null ){
	print "null\n";
}*/
odbc_close($link);
$link = mysql_connect("localhost", "dependns", "dependns@833");
mysql_select_db("dependns", $link);
$result = mysql_query($sql_query);
$row = mysql_fetch_row($result);
print "mysql:\t".$row[0]."\t".$row[1]."\n";
mysql_close();
?>
