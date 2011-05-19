<?php

require("dns.inc.php");
require("dnslookup.php");
require("Response.php");
require("Answer.php");
require("AnswerIP.php");
require("match.php");
require("IPChoose.php");
require("WhiteList.php");


$AskUrl = $_POST["ASK_URL"];
$User   = $_POST["User"];
$Passwd = $_POST["Passwd"];

// id check
$MD5_hash = md5($Passwd);

// set domain name 
if ( $AskUrl != "" ){
	$question=$AskUrl;
}else{
	echo "no url<br>\n";
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
	$resultList[$i] = $query_ans[$i]->Query($question,$type);
	if ($query_ans[$i]->error){
		echo"error!<br>\n";
	} else {
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

/*
   The flow of the follow code is going to send DNS Query to 6 resolvers.
   The result will be store into the database and calculate the counts of each results.
   In the end, history data will go through the match algorithm.
   The grade will be calculated by the algorithm.
*/
$odbc_id = odbc_connect("dependns",$DB_ID,$DB_PWD);
if ($odbc_id){
	// check password
	$sql_query = "select UserInfo.passwd from UserInfo where username = '".$User."';";
	$result = odbc_exec($odbc_id,$sql_query);
	if ( $result ){
		$row = odbc_fetch_array($result);
		echo $row['passwd']."\n";
		if ( $row['passwd'] != $MD5_hash ){
			odbc_close($odbc_id);
			echo "error login\n| error <br>";
			exit(0);
		}
	}

	// check table domain_id 
	$sql_query = "SELECT id FROM domain_id WHERE domain_name = '".$question."';";
	$result = odbc_exec($odbc_id,$sql_query);
	if ( !$result ){
		echo "can not select from table domain_id<br>\n";
	}else {
		$row = odbc_fetch_array($result);
		if ( $row['id'] == null ){
			$sql_query = "INSERT INTO domain_id (id,domain_name) VALUES( NULL , '".$question."');";

			odbc_exec($odbc_id,$sql_query);

			$sql_query = "SELECT id FROM domain_id WHERE domain_name = '".$question."';";     
			$result = odbc_exec($odbc_id,$sql_query);
			$newId = odbc_result($result,1);

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
			//echo "insert resolveAns into domain_".$row['id']."<br>";
			$id = $row['id'];
			for ( $i = 0 ;$i < count($resolverList) ; $i++ ){
				for ( $j = 0 ; 
				$j < $resultList[$i]->count ; 
				$j++ ) {

					if ( $resultList[$i]->results[$j]->type == 1 ){                              
						$sql_query = "select domain_id from domain_DB where domain_id = '".$id.
							"' and ip = '".$resultList[$i]->results[$j]->data.
							"' and resolver = '".$resolverList[$i]."';";
						$result = odbc_exec($odbc_id,$sql_query);
						$row = odbc_fetch_row($result);

						// add new ip when resolve ip change
						if ( $row == false ){	
							$sql_query = "INSERT INTO domain_DB (domain_id,ip,resolver) VALUES('"
								.$id."','"
								.$resultList[$i]->results[$j]->data."','"
								.$resolverList[$i]."')";
							odbc_exec($odbc_id,$sql_query);
						}
						$sql_query = "UPDATE domain_DB SET counter = counter+1 where domain_id = '".$id.
							"' and ip = '".$resultList[$i]->results[$j]->data.
							"' and resolver = '".$resolverList[$i].
							"';";
						odbc_exec($odbc_id,$sql_query);
					} 
				}
			}
			// do query
			$sql_query = "select ip , counter from domain_DB where domain_id = $id and resolver <> 'Tester' group by ip;";
			$result = odbc_exec($odbc_id,$sql_query);
			if ( $result ){
				while ( $row=odbc_fetch_array($result) ){
					$ip = $row['ip'];	
					$bClass = getBClass($ip);
					$flag = false;
					for ( $i = 0 ; $i < count($HistoryList) ; $i++ ){
						if ( $bClass == $HistoryList[$i]->getBClass() )	{
							$HistoryList[$i]->addIP($ip,$row['counter']);
							$flag = true;
							break;
						}
					}
					if (!$flag){
						$HistoryList[] = new Answer($bClass,$ip,$row['counter']);
					}
				}
			} else {
				echo "bad!<br>\n";
			}
		}
	}
	//}
	odbc_close($odbc_id);
}


// do dependns algorithm
echo "|\n";
$dolookup = new DNSLookup($question); 
$dolookup->run_algo( $resultList , $HistoryList , $oneTimeCount );

function getBClass( $ip ){
	$dotCount = 0;
	for ( $i = 0 ; $i < strlen($ip) ; $i++ ){
		if( substr( $ip , $i , 1 ) == "." ){
			$dotCount++;
		}
		if( $dotCount == 2 ){
			//echo substr($ip,0,$i);
			return substr($ip,0,$i);
		}
	}
	return "";
}

?>
