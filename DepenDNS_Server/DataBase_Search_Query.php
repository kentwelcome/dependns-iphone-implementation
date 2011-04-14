<?php


require("dns.inc.php");

$DB_host = "localhost";
$DB_ID   = "dependns";
$DB_PWD  = "dependns@833";

if ( $_SERVER['argc'] == 2 ){
	$question = $_SERVER['argv'][1];
} else {
	$question = "www.google.com";
}

if ( isset($_REQUEST['question']) ){
	$question=$_REQUEST['question'];
} 


$Config = parse_ini_file("dependns.ini",true);
$odbc_id = odbc_connect("dependns",$DB_ID,$DB_PWD);

// set resolver list
$tmp_array = $Config['ResolverList']['list'];
for ( $i = 0 ; $i < count($tmp_array) ; $i++ ){
	$resolverList[] = $tmp_array[$i];
}

if ($odbc_id){
	$sql_query = "SELECT id FROM domain_id WHERE domain_name = '".$question."';";
	$result = odbc_exec($odbc_id,$sql_query);
	if ( $result ){
		$row = odbc_fetch_array($result);

		// Can find data in the database
		if ( $row['id'] != null ){
			$id = $row['id'];
			$sql_query = "SELECT * FROM domain_DB WHERE domain_id = $id ORDER BY resolver;";
			$result = odbc_exec($odbc_id,$sql_query);
			if ( $result ){
				echo "<table border='1'>";
				echo "<tr>
					<th>ID</th>
					<th>IP</th>
					<th>Resolver</th>
					<th>Counter</th>
					</tr>";
				while ( $row = odbc_fetch_array($result) ){
					$ip 	= $row['ip'];
					$resolver = $row['resolver'];
					$counter  = $row['counter'];
					echo "<tr>";
					echo "<th>$id</th>\n";
					echo "<th>$ip</th>\n";
					echo "<th>$resolver</th>\n";
					echo "<th>$counter</th>\n";
					echo "</tr>";
				}	
				echo "</table>";
			} else {
				echo "Error: <br>\n";
			}
		} else {
			// Can't find data in database. Ask by DNS resolver
			echo "There is no domain_id of '$question' in DataBase.<br>\n";
			echo "Sending DNS query to Resolvers.<br>\n";

			// send DNS query
			if ( $Config['Configure']['Timeout'] ){
				$timeout=$Config['Configure']['Timeout'];
			} else {
				$timeout=10;
			}
			$port   =53;
			$udp    =true;
			$type   ="A";
			$debug  = "";

			echo "<table border=1>";
			echo "<tr>
				<th>IP</th>
				<th>Resolver</th>
				<th>Count</th>
				</tr>";
			for ( $i = 0 ;$i < count($resolverList) ; $i++ ){
				$query_ans[$i] = new DNSQuery($resolverList[$i],$port,$timeout,$udp,$debug);
				$resultList[$i] = $query_ans[$i]->Query($question,$type);
				if ($query_ans[$i]->error){
					echo"erroe!<br>\n";
				} else {
					$counter = 0;
					for ( $j = 0 ; $j < $resultList[$i]->count ; $j++ ){
						if ( $resultList[$i]->results[$j]->type == 1 ){
							$counter++;
						}
					}
					$oneTimeCount[$i] = $counter;

					for ( $x = 0 ; $x < $counter ; $x++ ){
						echo "<tr>";
						echo "<th>".$resultList[$i]->results[$x]->data."</th>";
						echo "<th>".$resolverList[$i]."</th>";
						echo "<th>".$resultList[$i]->count."</th>";
						echo "</tr>";
					}

				}
			}
			echo "</table>";

		}
	} else {
		echo "Error: Can't find domain_id of '$question' from DataBase<br>\n";
		exit();
	}
}



?>
