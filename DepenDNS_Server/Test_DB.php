<?php

require("dns.inc.php");
require("dnslookup.php");
require("Response.php");
require("Answer.php");
require("AnswerIP.php");
require("match.php");
require("IPChoose.php");


if (isset($_REQUEST['question']))
	$question=$_REQUEST['question'];
else{  
	echo "no url<br>";
	exit(0);
}

// read configure file from dependns.ini
$Config = parse_ini_file("dependns.ini",true);

// set resolver list
$tmp_array = $Config['ResolverList']['list'];
for ( $i = 0 ; $i < count($tmp_array) ; $i++ ){
	$resolverList[] = $tmp_array[$i];
}

// set History List
$HistoryList = array();


// send dns query
if ( $Config['Configure']['Timeout'] ){
	$timeout=$Config['Configure']['Timeout']; 
} else {
	$timeout=10;
}
$port	=53;
$udp	=true;
$type	="A";
$debug	= "";

for ( $i = 0 ;$i < count($resolverList) ; $i++ ){
	$query_ans[$i] = new DNSQuery($resolverList[$i],$port,$timeout,$udp,$debug); 
	if ($query_ans[$i]->error){
		echo"Error: Can't access resolver $resolverList[$i]<br>\n";
	} else {
		$resultList[$i] = $query_ans[$i]->Query($question,$type);
		$counter = 0;
		for ( $j = 0 ; $j < $resultList[$i]->count ; $j++ ){
			if ( $resultList[$i]->results[$j]->type == 1 ){
				$counter++;
			}
		}
		$oneTimeCount[$i] = $counter;
	}
}

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
if ($odbc_id){

	// check table domain_id 
	$sql_query = "SELECT id FROM domain_id WHERE domain_name = '".$question."';";
	$result = odbc_exec($odbc_id,$sql_query);
	if ( !$result ){
		echo "can not select from table domain_id<br>\n";
	}else {
		$row = odbc_fetch_array($result);
		if ( $row['id'] == null ){
			echo "Insert $question to domain_id.<br>\n";
			$sql_query = "INSERT INTO domain_id (id,domain_name) VALUES( NULL , '".$question."');";

			odbc_exec($odbc_id,$sql_query);

			$sql_query = "SELECT id FROM domain_id WHERE domain_name = '".$question."';";     
			$result = odbc_exec($odbc_id,$sql_query);
			$newId = odbc_result($result,1);


			// insert DNS result to domain_DB
			for ( $i = 0 ; $i < count($resolverList) ; $i++ ){
				for ( $j = 0 ; $j < $resultList[$i]->count ; $j++ ){
					if ( $resultList[$i]->results[$j]->type == 1 ){
						$sql_query = "INSERT INTO domain_DB (domain_id,ip,resolver) VALUES('"
							.$newId."','"
							.$resultList[$i]->results[$j]->data."','"
							.$resolverList[$i]."')";
						odbc_exec($odbc_id,$sql_query);
					}
				}
			}
		}else{
			echo "Insert resolveAns into domain_".$row['id']."<br>";
			$id = $row['id'];
			for ( $i = 0 ;$i < count($resolverList) ; $i++ ){
				for ( $j = 0 ; 
				$j < $resultList[$i]->count ; 
				$j++ ) {

					// Update the resolver counter
					if ( $resultList[$i]->results[$j]->type == 1 ){                              
						$sql_query = "select domain_id from domain_DB where domain_id = '".$id.
							"' and ip = '".$resultList[$i]->results[$j]->data.
							"' and resolver = '".$resolverList[$i]."';";
						$result = odbc_exec($odbc_id,$sql_query);
						$row = odbc_fetch_row($result);

						// add new ip when resolve ip change
						if ( $row == false ){	
							echo "Insert new ip ".$resultList[$i]->results[$j]->data to domain_$id."<br>\n";
							$sql_query = "INSERT INTO domain_DB (domain_id,ip,resolver) VALUES('"
								.$id."','"
								.$resultList[$i]->results[$j]->data."','"
								.$resolverList[$i]."')";
							odbc_exec($odbc_id,$sql_query);
						}

						// Update the counter
						$sql_query = "UPDATE domain_DB SET counter = counter+1 where domain_id = '".$id.
							"' and ip = '".$resultList[$i]->results[$j]->data.
							"' and resolver = '".$resolverList[$i].
							"';";
						odbc_exec($odbc_id,$sql_query);
					} 
				}
			}
			// Calculate the sum of counter 
			$sql_query = "select ip , counter from domain_DB where domain_id = $id and resolver <> 'Tester' group by ip , counter;";
			$result = odbc_exec($odbc_id,$sql_query);
			if ( $result ){
				while ( $row=odbc_fetch_array($result) ){
					$ip = $row['ip'];	
					$bClass = getBClass($ip);
					$flag = false;
					for ( $i = 0 ; $i < count($HistoryList) ; $i++ ){
						if ( $bClass == $HistoryList[$i]->getBClass() )	{
							$num = $row['counter'];
							$HistoryList[$i]->addIP($ip,$num);
							$flag = true;
							break;
						}
					}
					if (!$flag){
						$num = $row['counter'];
						$HistoryList[] = new Answer($bClass,$ip,$num);
					}
				}
			} else {
				echo "Error: Can't find the result of domain_$id.<br>\n";
			}
		}
	}
	odbc_close($odbc_id);
}


// do dependns algorithm
echo "<br>Usable IP of $question<br>\n";
$dolookup = new DNSLookup(); 
$dolookup->run_algo( $resultList , $HistoryList , $oneTimeCount );

function getBClass( $ip ){
	$dotCount = 0;
	for ( $i = 0 ; $i < strlen($ip) ; $i++ ){
		if( substr( $ip , $i , 1 ) == "." ){
			$dotCount++;
		}
		if( $dotCount == 2 ){
			return substr($ip,0,$i);
		}
	}
	return "";
}

?>
