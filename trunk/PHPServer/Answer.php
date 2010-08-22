<?
class Answer
{
	var $classCount = 0;
	var $classCountPercent = 0;
	var $ipList = array();

	function Answer( $BClass , $ip , $times ){
		if ( !$BClass && !$ip ){
			$this->BClass = "";
			$this->classCount = 0;
			$this->classCountPercent = 0.0;
		} else {
			$this->BClass = $BClass;
			$this->classCount = 0;
			$this->classCountPercent = 0.0;
			$this->addIP($ip,$times);
		}

	}

	function addIP( $ip , $times ){
		for ( $i = 0 ; $i < count($this->ipList) ; $i++ ){
			$AnsIP = $this->ipList[$i];
			if ( $ip == $AnsIP->getIP() ){
				$this->ipList[$i]->addCount();
				$this->classCount+=$times;
				return 0;
			}
		}
		$this->ipList[] = new AnswerIP($ip,$times);
		$this->classCount+=$times;
		return -1;
	}

	function setClassCountPercent ( $resolcerCount ){
		$this->classCountPercent = $this->classCount / $resolcerCount;
		$this->classCountPercent = floor($this->classCountPercent*1000)/1000;

		for ( $i = 0 ; $i < count($this->ipList) ; $i++ ){
			$this->ipList[$i]->setCountPercent($resolcerCount);
		}
	}

	function getBClass(){
		return $this->BClass;
	}
	function getClassCount(){
		return $this->classCount;
	}

	function getClassCountPercent(){
		return $this->classCountPercent;
	}

	function getIPList(){
		return $this->ipList;
	}
	/*
	function printAnswer(){
		for( $i = 0 ; $i < count($this->ipList) ; $i++ ){
			$IP = $this->ipList[$i];
			//display("IP " + (i+1) + ": " + IP.getIP() + "&nbsp;" + IP.getCount() + "&nbsp;" + IP.getCountPercent());
			//echo "IP ".($i+1).": ".$IP->getIP()." ".$IP->getCount()." ".$IP->getCountPercent()."<br>";
		}
		// todo fix with display in HTML 
	}*/
	
}

?>
