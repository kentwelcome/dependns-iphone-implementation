<?php
$DB_host = "localhost";
$DB_ID   = "dependns";
$DB_PWD  = "dependns@833";

if ( $_SERVER['argc'] == 2 ){
	$question = $_SERVER['argv'][1];
} else {
	$question = "www.google.com";
}

$odbc_id = odbc_connect("dependns",$DB_ID,$DB_PWD);

if ($odbc_id){
	$sql_query = "SELECT id FROM domain_id WHERE domain_name = '".$question."';";
	$result = odbc_exec($odbc_id,$sql_query);
	if ( $result ){
		$row = odbc_fetch_array($result);
		if ( $row['id'] == null ){
			$id = $row['id'];
			$sql_query = "SELECT * FROM domain_DB WHERE domain_id = $id;";
			$result = odbc_exec($odbc_id,$sql_query);
			if ( $result ){
				while ( $row = odbc_fetch_array($result) ){
					$ip 	= $row['ip'];
					$resolver = $row['resolver'];
					$counter  = $row['counter'];
					echo "IP: $ip<br>\n";
					echo "resolver: $resolver<br>\n";
					echo "counter:  $counter<br>\n";
				}	
			}
		} else {
			echo "Error: There is no domain_id of '$question' in DataBase.<br>\n";
		}
	} else {
		echo "Error: Can't find domain_id of '$question' from DataBase<br>\n";
		exit();
	}
}



?>
