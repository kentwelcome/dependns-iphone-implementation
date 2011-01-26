<?

Class AnswerIP{
	var $count;
	var $countPercent;
	var $a , $b , $c;
	var $canRandom;
	var $ip;
	
	function AnswerIP($ip,$times){
		if (!$ip && !$times){
			$this->ip = "";
			$this->count = 0;
			$this->canRandom = false;
			$this->a = 0;
			$this->b = 0;
			$this->c = 0;
		} else {
			$this->ip = $ip;
			$this->count = $times;
			if ( $this->count >= 4 )
				$this->setCanRandom(true);
			$this->canRandom = false;
			$this->a = 0;
			$this->b = 0;
			$this->c = 0;
		}
	}

	function addCount(){
		$this->count++;
		if ( $this->count == 4 ){
			$this->setCanRandom(true);
		}

	}
	function setCount($times){
		$this->count = $times;
		if ( $this->count >= 4 )
			$this->setCanRandom(true);
	}
	function setCountPercent( $bClassTotalCount ){
		$this->countPercent = $this->count / $bClassTotalCount;
		$this->countPercent = ( floor($this->countPercent*1000) )/1000.0;
	}

	function setCanRandom( $canRandom ){
		$this->canRandom = $canRandom;
	}

	function setA($A){
		$this->a = $A;
	}
	function setB($B){
		$this->b = $B;
	}
	function setC($C){
		$this->c = $C;
	}
	function getIP(){
		return $this->ip;
	}
	function getCount(){
		
		return $this->count;
	}
	function getCountPercent(){
		return $this->countPercent;
	}
	function getA(){
		return $this->a;
	}
	function getB(){
		return $this->b;
	}
	function getC(){
		return $this->c;
	}
	function getcanRandom(){
		return $this->canRandom;
	}

}
?>
