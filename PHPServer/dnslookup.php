<?

class DNSLookup {
	var $domainName;
	var $resultIngo;
	var $type;
	var $resolverCount;
	//var sr;
	var $resolverList = array();
	var $lookupThread;
	var $historyThread;
	var $answerList = array();
	var $response;
	function DNSLookup(){
		$this->response = new Response();
	}

	function run_algo( $ResolveAns , $HistoryList , $oneTimeCount ){
			
		// set resolver count
		$this->resolverCount = 17;


		for ( $i = 0 ; $i < count($ResolveAns) ; $i++ ){
			//echo $ResolveAns[$i];
			for ( $j = 0 ; $j < $ResolveAns[$i]->count ; $j++ ){
				if ( $ResolveAns[$i]->results[$j]->type == 1 ){
					$ip = $ResolveAns[$i]->results[$j]->data;
					$this->response->addToAnswerList($ip,32);
				}
			}
		}
		$this->orderResponse();
		$mode_OneTimeCount = $this->checkOneTimeCount( $oneTimeCount );
		for ( $i = 0 ; $i < count($this->answerList) ; $i++ ){
		//	for ( $j = 0 ; $j < count($this->answerList[$i]->ipList) ; $j++ )
			//echo "BClass: ".$this->answerList[$i]->getBClass()." times:".$this->answerList[$i]->classCount."<br>";
		}
		$match = new Match( $this->answerList , $HistoryList , $mode_OneTimeCount );
		$match->runMatchAlgorithm($this->resolverCount);

		$ipchoice = new IPChoice( $match->getIPListAll() , $match->getRegion() );
		$ipchoice->countGrade();

		echo "Greade: ".$ipchoice->Grade."<br>\n";


	}

	function orderResponse(){
		$response = $this->response;
		$answerIPList = $response->getAnswerIPList();
		for( $i = 0 ; $i < $response->getCount() ; $i++ ){
			$bClass = $this->getBClass($answerIPList[$i]);
			$ok = false;
			for( $j = 0 ; $j < count($this->answerList) ; $j++ ){
				$Ans = $this->answerList[$j];
				if( $bClass == $Ans->getBClass() )
				{
					$Ans->addIP($answerIPList[$i],1);
					//echo "add".$answerIPList[$i]."<br>";
					$ok = true;
					break;
				}
			}
			if( !$ok ){
				$this->answerList[] = new Answer($bClass , $answerIPList[$i] , 1 );
				//echo "add new Answer<br>";
			}
		}

	}

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

	function checkOneTimeCount( $OneTimeCount ){
		$countList = array(10);
		for ( $i = 0 ; $i < 10 ; $i++ ){
			$ConTmp = Array(2);
			$ConTmp[0] = 0;
			$ConTmp[1] = 0;
			$countList[$i] = $ConTmp;
		}
		$mode = 0;
		$modeIndex = 0;
		$arraySize = 0;
		for ( $i = 0 ; $i < $this->resolverCount ; $i++ ){
			$exist = false;
			for ( $j = 0 ; $j < $arraySize ; $j++ ){
				$ConTmp = $countList[$j];
				if ( $ConTmp[0] == $OneTimeCount[$i]){
					$countList[$arraySize][1]++;
					$exist = true;
				}
			}
			if (!$exist){
				$countList[$arraySize][0] = $OneTimeCount[$i];
				$countList[$arraySize][1] = 1;
				$arraySize++;
			}
		}
		$ConTmp = $countList[$modeIndex];
		return $ConTmp[0];
	}
}

?>
