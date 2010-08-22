<?
class Response{
	var $count = 0;
	var $answerIPList = array();
	var $answerTTLList = array();
	function addToAnswerList( $ip , $ttl ){
		$this->answerIPList[] = $ip;
		$this->answerTTLList[] = $ttl;
		$this->count++;
	}
	
	function getAnswerIPList(){
		return $this->answerIPList;
	}
	function getAnswerTTLList(){
		return $this->answerTTLList;
	}
	function getCount(){
		return $this->count;
	}
	function clear(){
		$this->answerIPList = null;
		$this->answerTTLList = null;
		$this->count = 0;
	}
}

?>
