<?php
//
//  CheckID.php
//  DepenDNS
//
//
//  Created by Kent Huang on 2011/5/12.
//  Copyright 2010 Kent Huang. All rights reserved.
//

// Read User Name and Passwoed by POST

if (isset($_POST['User'])){
	$USER = $_POST['User'];
} else {
	exit();
}
if (isset($_POST['Passwd'])){
	$PASS = md5($_POST['Passwd']); 
} else {
	exit();
}

// read configure file from dependns.ini
$Config = parse_ini_file("dependns.ini",true);

// Set Database information
$DB_host = $Config['DataBase']['SQL_Server'];
$DB_ID   = $Config['DataBase']['SQL_ID'];
$DB_PWD  = $Config['DataBase']['SQL_PWD'];

// Connect to DepenDNS Server to authenticate User
$odbc_id = odbc_connect("dependns",$DB_ID,$DB_PWD);
if (!$odbc_connect){
	//print "Server Down\n";
	exit();
}

$SQL = "SELECT UserInfo.uid WHERE UserInfo.username = '$USER' AND UserInfo.passwd = '$PASS'";
$result = odbc_exec($odbc_id,$SQL);

if ($result){
	$row = odbc_fetch_array($result);

	$if ( isset( $row['uid'] ) ){
		$UID = $row['uid'];
		print ("$PASS");
	} else {
		exit();
	}
}
?>
