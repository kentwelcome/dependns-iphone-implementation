<?php

require("dns.inc.php");
require("dnslookup.php");
require("Response.php");
require("Answer.php");
require("AnswerIP.php");
require("match.php");
require("IPChoose.php");


$AskUrl	= $_POST["ASK_URL"];
$User 	= $_POST["User"];
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
		echo"erroe!<br>\n";
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
$link = mysql_connect("localhost", "dependns", "dependns@833");
if ($link){
	if ( mysql_select_db("dependns", $link) ){
		// check user passwd 
		$sql_query = "select UserInfo.passwd from UserInfo where username = '".$User."';";
		$result = mysql_query($sql_query);
		if ( $result ){
			$row = mysql_fetch_row($result);
			echo $row[0]."\n";	
			if ( $row[0] != $MD5_hash ){
				mysql_close();
				echo "error login\n| error <br>";
				exit(0);
			}
		}


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
			}
		}
	}
}

mysql_close();

// do dependns algorithm
echo "|\n";
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
