<?php

class WhiteList 
{
	var $AnswerIPList;	// The orgenal IP results from match algorithm 
	var $WhiteIPList;	// The white ip list from the history data
	var $DomainName;	// Domain Name yout want to search in white list
	var $ID;		// Domain ID in the Database

	// Main function of WhitList
	function WhiteList ( $url , $iplist )
	{
		$this->AnswerIPList 	= $iplist;
		$this->DomainName 	= $url;
	}

	// Get the White List Data from Database
	function SyncWithDataBase ()
	{
		// read configure file from dependns.ini
		$Config = parse_ini_file("dependns.ini",true);
		if ( $Config['DataBase'] ) {
			$DB_host = $Config['DataBase']['SQL_Server'];
			$DB_ID   = $Config['DataBase']['SQL_ID'];
			$DB_PWD  = $Config['DataBase']['SQL_PWD'];
		} else {
			$DB_host = "localhost";
			$DB_ID   = "dependns";
			$DB_PWD  = "dependns@833";
		}

		// Connect to Database
		$odbc_id = odbc_connect("dependns",$DB_ID,$DB_PWD);
		if (!$odbc_id){
			return false;
		}

		// Check the domain name white list whether exist.
		$SQL = "SELECT WhiteList.domain_id FROM WhiteList , domain_id WHERE domain_id.id = WhiteList.domain_id AND domain_id.domain_name = '$this->DomainName';";
		$result = odbc_exec($odbc_id,$SQL);
		if ($result){
			// Domain Name With White List
			$row = odbc_fetch_array($result);
			if ($row['domain_id'] == null){
				odbc_close($odbc_id);
				return false;
			}
			$this->ID = $row['domain_id'];
		} else {
			// Domain Name Without White List
			odbc_close($odbc_id);
			return false;
		}


		// Search the White List data from Database
		$SQL = "SELECT ip FROM domain_DB WHERE domain_id = '$this->ID' group by ip;";
		$result = odbc_exec($odbc_id,$SQL);
		if ($result){
			for ($i = 0 ; $row = odbc_fetch_array($result) ; $i++){
				$this->WhiteIPList[$i] = $row['ip'];
			}
		} else {
			odbc_close($odbc_id);
			return false;
		}
		odbc_close($odbc_id);
		return true;
	}
	
	function DisplayWhiteList ()
	{
		for ($i = 0 ; $i < count($this->WhiteIPList) ; $i++ ){
		 	// White list ip not in Answer ip List then display
			if ($this->ExistInAnswerList($this->WhiteIPList[$i]) == false){
				echo $this->WhiteIPList[$i]."<br>\n";	
			}	
		}
	}

	function DisplayAnswerList()
	{	
		for ($i = 0 ; $i < count($this->AnswerIPList) ; $i++){
			echo $this->AnswerIPList[$i]->ip."<br>";
		}
	}

	function ExistInAnswerList ($ip){
		for ($i = 0 ; $i < count($this->AnswerIPList) ; $i++ ){
			// $ip is in the AnswerIPList
			if (strcmp($ip,$this->AnswerIPList[$i]->ip) == 0){
				return true;	
			}
		}
		return false;
	}
}
?>
