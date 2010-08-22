<?
Class Match {
	var $IpListAll = array();
	var $IpHistoryList = array();
	var $region;
	var $AnswerList;
	var $HistoryList;
	var $oneTimeCount;

	function Match( $AnswerList , $HistoryList , $oneTimeCount ){
		$this->AnswerList = $AnswerList;
		$this->HistoryList = $HistoryList;
		$this->oneTimeCount = $oneTimeCount;
	}

	function runMatchAlgorithm( $resolverCount ){
		$this->arrangeAnswer( $resolverCount );
		//$this->printAnswer();
		//echo "alpha<br>";
		$this->ipDifference(); //alpha
		//echo "beta<br>";
		$this->historyDifference(); //beta
		//echo "gamma<br>";
		$this->bClassDifference(); //gamma
		$this->countRegion();
		//echo "region: $this->region<br>";
		//echo "A:".$this->IpListAll[0]->getA();
	}       

	function countRegion()
	{
		$this->region = count($this->IpListAll) / $this->oneTimeCount;;
	}

	function ipDifference(){
		for ( $i = 0 ; $i < count($this->AnswerList) ; $i++ ){ 
			$Ans = $this->AnswerList[$i];
			$ipList = $Ans->getIPList();

			// array List addAll
			for ( $j = 0 ; $j < count($ipList) ; $j++ ){
				$this->IpListAll[] = $ipList[$j];	
			}
			//$this->IpListAll->addAll($ipList);
		}
		$n_max = 0;
		for ( $i = 0 ; $i < count($this->IpListAll) ; $i++ ){
			$AnsIP = $this->IpListAll[$i];
			$tmp = $AnsIP->count;
			if ( $tmp > $n_max ){
				$n_max = $tmp;
			}
		}
		$confidence = 0.80;

		//Count alapha
		for( $i = 0 ; $i < count($this->IpListAll) ; $i++ ){
			$Ans = $this->IpListAll[$i];
			if ( $Ans->count >= $n_max*$confidence ){
				$Ans->setA(1);
			}

		}
	}

	function historyDifference() {
		for ( $i = 0 ; $i < count($this->HistoryList) ; $i++ )
		{
			$His = $this->HistoryList[$i];
			$ipList = $His->getIPList();
			for ( $j = 0 ; $j < count($ipList) ; $j++ ){
				$this->IpHistoryList[] = $ipList[$j];
				//echo $ipList[$i]->ip."<br>";
			}
		}
		for ( $i = 0 ; $i < count($this->IpListAll) ; $i++ )
		{
			$iplist = $this->IpListAll[$i];
			$ip1 = $iplist->ip;
			for ( $j = 0 ; $j < count($this->IpHistoryList) ; $j++ )
			{
				$HisIP = $this->IpHistoryList[$j];
				$ip2 = $HisIP->ip;
				if( $ip1 == $ip2 )
				{
					$iplist->setB(1);
					break;
				}
			}
		}
	}

	function bClassDifference(){
		if ( count($this->AnswerList) == 1)
		{
			$Ans = $this->AnswerList[0];
			$bClass = $Ans->getBClass();
			$tempIP = array();

			for ( $i = 0 ; $i < count($this->HistoryList) ; $i++ )
			{
				$His = $this->HistoryList[$i];
				if( $bClass == $His->getBClass() )
				{
					$tempIP = $His->getIPList();
					break;
				}

			}

			for( $i = 0 ; $i < count($this->IpListAll) ; $i++ )
			{
				$AnsIP = $this->IpListAll[$i];
				$ip = $AnsIP->ip;
				for( $j = 0 ; $j < count($tempIP) ; $j++ )
				{
					$temp = $tempIP[$j];
					if( $ip == $temp->ip )
					{
						$difference = $AnsIP->getCountPercent() - $temp->getCountPercent();
						//echo $difference ." ".$AnsIP->getCountPercent()."  ".$temp->getCountPercent()."<br>";
						if ( abs($difference) < 0.10 )
						{
							$AnsIP->setC(1);
						}
					}       
				}       
			}
		} else  { 

			for( $i = 0 ; $i < count($this->AnswerList) ; $i++)
			{
				$Ans = $this->AnswerList[$i];
				$bClass = $Ans->getBClass();
				for( $j = 0 ; $j < count($this->HistoryList) ; $j++ )
				{
					$His = $this->HistoryList[$j];
					if( $bClass == $His->getBClass() )
					{
						//echo $bClass."<br>";
						$difference = $Ans->getClassCountPercent() - $His->getClassCountPercent();
						//display("DIFF"+difference);
						//echo $difference ." ".$Ans->getClassCountPercent()." ". $His->getClassCountPercent() ."<br>";
						if( abs($difference) < 0.10 )
						{
							//$temp = array();
							$temp = $Ans->getIPList();
							for ( $x = 0 ; $x < count($temp) ; $x++ )
							{
								$TempIP = $temp[$x];
								$tempIP = $TempIP->ip;
								for( $y = 0 ; $y < count($this->IpListAll) ; $y++ )
								{
									$AnsIP = $this->IpListAll[$y];
									if( $TempIP->ip == $AnsIP->ip )
									{
										$AnsIP->setC(1);
									}
								}
							}
						}
					}
				}
			}

		}
	}

	function arrangeAnswer( $resolverCount ){
		for( $i = 0 ; $i < count($this->AnswerList) ; $i++ )
		{
			$Ans = $this->AnswerList[$i];
			//display(Ans);
			$Ans->setClassCountPercent($resolverCount);
		}

		$sum_of_data = 0;
		for( $i = 0 ; $i < count($this->HistoryList) ; $i++ ){
			$sum_of_data += $this->HistoryList[$i]->getClassCount();
		}
		//echo $sum_of_data."<br>";
		for( $i = 0 ; $i < count($this->HistoryList) ; $i++ )
		{
			$this->HistoryList[$i]->setClassCountPercent($sum_of_data); // 336 ?
		}

	}

	function printAnswer(){
		for( $i = 0 ; $i < count($this->HistoryList) ; $i++ ){
			//var Ans = AnswerList.get(i);
			$His = $this->HistoryList[$i];
			$temp = $His->getClassCount()/48.0;
			$temp = floor($temp*1000) / 1000.0;
			$His->printAnswer();
		}
		for( $i = 0 ; $i < count($this->AnswerList) ; $i++ ){
			$Ans = $this->AnswerList[$i];
		}
	}

	function getIPListAll(){
		return $this->IpListAll;
	}

	function getRegion(){
		return $this->region;
	}
}
?>
