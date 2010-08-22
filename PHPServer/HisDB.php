<?php

require("dns.inc.php");
require("dnslookup.php");
require("Response.php");
require("Answer.php");
require("AnswerIP.php");
require("match.php");
require("IPChoose.php");

class HisDB{

	function HisDB( $question ){
		// set resolver list
		$this.resolverList[] = "168.95.1.1";
		$this.resolverList[] = "168.95.192.1";
		$this.resolverList[] = "139.175.55.244";
		$this.resolverList[] = "139.175.252.16";
		$this.resolverList[] = "139.175.150.20";
		$this.resolverList[] = "139.175.10.20";
		$this.resolverList[] = "203.187.0.6";
		$this.resolverList[] = "203.133.1.8";
		$this.resolverList[] = "211.78.130.1";
		$this.resolverList[] = "211.78.130.2";
		$this.resolverList[] = "61.56.211.185";
		$this.resolverList[] = "211.78.215.200";
		$this.resolverList[] = "211.78.215.137";
		$this.resolverList[] = "210.200.211.193";
		$this.resolverList[] = "210.200.211.225";
		$this.resolverList[] = "203.79.224.10";
		$this.resolverList[] = "203.79.224.30";

		$this.oneTimeCount = array();
		// set History List
		$this.HistoryList = array();
		$thos.resultList = array();

		// send dns query
		$this.port=53;
		$this.timeout=60;
		$this.udp=true;
		$this.type="A";
		$this.question = $question;
	}


	function SensQuery(){

		for ( $i = 0 ;$i < count($this.resolverList) ; $i++ ){
			$query_ans[$i] = new DNSQuery($this.resolverList[$i],
					$this.port,
					$this.timeout,
					$this.udp,
					$debug); 

			$this.resultList[$i] = $query_ans[$i]->Query($this.question,$this.type);
			if ($query_ans[$i]->error){
				echo"erroe!<br>\n";
			} else {
				$counter = 0;
				for ( $j = 0 ; $j < $this.resultList[$i]->count ; $j++ ){
					if ( $this.resultList[$i]->results[$j]->type == 1 ){
						$counter++;
					}
				}
				$this.oneTimeCount[$i] = $counter;
			}
		}
	}

	// check history database
	// db link
	function LinkDB()
	{
		$link = mysql_connect("localhost", "dependns", "dependns@833");
		if ( mysql_select_db("dependns", $link) ){
			if ( mysql_select_db("dependns", $link) ){
				$sql_query = "SELECT id 
					FROM domain_id 
					WHERE domain_name = '".$this.question."';";
				$result = mysql_query($sql_query);
				if ( !$result ){
					echo "can not select from table domain_id<br>\n";
				}else {
					$row = mysql_fetch_row($result);
					if ( $row[0] == null ){
						//echo "empty<br>";
						$sql_query = "INSERT INTO domain_id 
							(id,domain_name) VALUES( NULL , '".$this.question."');";

						mysql_query($sql_query);

						$sql_query = "SELECT id 
							FROM domain_id 
							WHERE domain_name = '".$this.question."';";     
							mysql_query($sql_query);
						$newId = mysql_result(mysql_query($sql_query),0);
						$sql_query = "CREATE TABLE domain_".$newId."
							(`id` BIGINT( 255 ) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
							 `round` INT( 255 ) UNSIGNED NOT NULL,
							 `ip` VARCHAR( 16 ) NOT NULL,
							 `ttl` BIGINT( 255 ) UNSIGNED NOT NULL,
							 `date_time` DATETIME NOT NULL,
							 `resolverIP` VARCHAR( 16 ) NOT NULL)ENGINE = MYISAM";
						mysql_query($sql_query);
					}else{
						$id = $row[0];
						for ( $i = 0 ;$i < count($this.resolverList) ; $i++ ){
							for ( $j = 0 ; 
									$j < $this.resultList[$i]->count ; 
									$j++ ) {

								if ( $this.resultList[$i]->results[$j]->type == 1 ){                              
									$sql_query = "INSERT INTO domain_"
										.$id.
										"(id,ip,resolverIP) VALUES(NULL,'"
										.$this.resultList[$i]->results[$j]->data.
										"','"
										.$this.resolverList[$i].
										"');";
									mysql_query($sql_query);
								} 
							}
						}
						// do query
						$sql_query = "select ip , count(ip) 
							from domain_$id 
							group by ip;";
						//echo $sql_query;
						$result = mysql_query($sql_query);
						if ( $result ){
							while ( $row=mysql_fetch_row($result) ){
								$ip = $row[0];	
								$bClass = this.getBClass($ip);
								$flag = false;
								for ( $i = 0 ; $i < count($this.HistoryList) ; $i++ ){
									if ( $bClass == $this.HistoryList[$i]->getBClass() )	{
										$this.HistoryList[$i]->addIP($ip,$row[1]);
										$flag = true;
										break;
									}
								}
								if (!$flag){
									$this.HistoryList[] = new Answer($bClass,$ip,$row[1]);
								}
							}
						} else {
							echo "bad!<br>\n";
						}
					}
				}
			}

			mysql_close();


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

	}
}
?>
