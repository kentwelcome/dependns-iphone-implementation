<?php

require("dns.inc.php");
require("dnslookup.php");
require("Response.php");
require("Answer.php");
require("AnswerIP.php");
require("match.php");
require("IPChoose.php");


// set domain name 
if (isset($_REQUEST['question'])) 
	$question=$_REQUEST['question'];
else{
	echo "no url<br>";
	exit(0);
}
if (isset($_REQUEST['connectIP'])) 
        $connectIP=$_REQUEST['connectIP'];

// set resolver list

$resolverList[] = "168.95.1.1";
$resolverList[] = "168.95.192.1";
$resolverList[] = "139.175.55.244";
$resolverList[] = "139.175.252.16";
$resolverList[] = "139.175.150.20";
$resolverList[] = "139.175.10.20";
$resolverList[] = "203.187.0.6";
$resolverList[] = "203.133.1.8";
$resolverList[] = "211.78.130.1";
$resolverList[] = "211.78.130.2";
$resolverList[] = "61.56.211.185";
$resolverList[] = "211.78.215.200";
$resolverList[] = "211.78.215.137";
$resolverList[] = "210.200.211.193";
$resolverList[] = "210.200.211.225";
$resolverList[] = "203.79.224.10";
$resolverList[] = "203.79.224.30";

// set History List
$HistoryList = array();

//echo "test: ".$question."<br>";

//for ( $i = 0 ;$i < count($resolverList) ; $i++ ){
//	echo $resolverList[$i]."<br>";
//}

// send dns query
$port=53;
$timeout=60;
$udp=true;
$type="A";

for ( $i = 0 ;$i < count($resolverList) ; $i++ ){
	$query_ans[$i] = new DNSQuery($resolverList[$i],
			$port,
			$timeout,
			$udp,
			$debug); 


	$resultList[$i] = $query_ans[$i]->Query($question,$type);
	if ($query_ans[$i]->error){
		echo"erroe!<br>\n";
	} else {
		$counter = 0;
		for ( $j = 0 ; $j < $resultList[$i]->count ; $j++ ){
			if ( $resultList[$i]->results[$j]->type == 1 ){
				//echo "DNS".$i.": ".$resultList[$i]->results[$j]->data."<br>";
				$counter++;
			}
		}
		$oneTimeCount[$i] = $counter;
	}
}

// check history database
// db link
$link = mysql_connect("localhost", "dependns", "dependns@833");
if ( mysql_select_db("dependns", $link) ){
	// check table domain_id 
	$sql_query = "SELECT id FROM domain_id WHERE domain_name = '".$question."';";
	$result = mysql_query($sql_query);
	if ( !$result ){
		echo "can not select from table domain_id<br>\n";
	}else {
		$row = mysql_fetch_row($result);
		if ( $row[0] == null ){
			//echo "empty<br>";
			$sql_query = "INSERT INTO domain_id (id,domain_name) VALUES( NULL , '".$question."');";
			
			mysql_query($sql_query);

			$sql_query = "SELECT id FROM domain_id WHERE domain_name = '".$question."';";     
			mysql_query($sql_query);
			$newId = mysql_result(mysql_query($sql_query),0);
			$sql_query = "CREATE TABLE domain_".$newId."(`id` BIGINT( 255 ) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,`round` INT( 255 ) UNSIGNED NOT NULL,`ip` VARCHAR( 16 ) NOT NULL,`ttl` BIGINT( 255 ) UNSIGNED NOT NULL,`date_time` DATETIME NOT NULL,`resolverIP` VARCHAR( 16 ) NOT NULL)ENGINE = MYISAM";
			//echo "create table domain_".$newId."<br>";
			mysql_query($sql_query);
		}else{
			//echo "insert resolveAns into domain_".$row[0]."<br>";
			$id = $row[0];
			for ( $i = 0 ;$i < count($resolverList) ; $i++ ){
				for ( $j = 0 ; 
				      $j < $resultList[$i]->count ; 
				      $j++ ) {

					if ( $resultList[$i]->results[$j]->type == 1 ){                              
						$sql_query = "INSERT INTO domain_"
							.$id.
							"(id,ip,resolverIP) VALUES(NULL,'"
							.$resultList[$i]->results[$j]->data.
							"','"
							.$resolverList[$i].
							"');";
						mysql_query($sql_query);
					} 
				}
			}
			// do query
			$sql_query = "select ip , count(ip) from domain_$id group by ip;";
			//echo $sql_query;
			$result = mysql_query($sql_query);
			if ( $result ){
				while ( $row=mysql_fetch_row($result) ){
					$ip = $row[0];	
					$bClass = getBClass($ip);
					$flag = false;
					for ( $i = 0 ; $i < count($HistoryList) ; $i++ ){
						if ( $bClass == $HistoryList[$i]->getBClass() )	{
							$HistoryList[$i]->addIP($ip,$row[1]);
							$flag = true;
							break;
						}
					}
					if (!$flag){
						$HistoryList[] = new Answer($bClass,$ip,$row[1]);
					}
				}
			} else {
				echo "bad!<br>\n";
			}
			// get number of history data
		}
	}
}

mysql_close();

for ( $i = 0 ; $i < count($HistoryList) ; $i++ ){
	//for ( $j = 0 ; $j < count($HistoryList[$i]->ipList) ; $j++ ){
	//echo $HistoryList[$i]->ipList[$j]->ip." times: ".$HistoryList[$i]->ipList[$j]->count."<br>";
	//}
	//echo $HistoryList[$i]->getBClass()." times: ".$HistoryList[$i]->classCount."<br>";
}

// do dependns algorithm
$dolookup = new DNSLookup(); 
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
