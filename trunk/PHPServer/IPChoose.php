<?

class IPChoice {
		var $region;
		var $ipListAll;
		var $ipListCanRandom = array();
		var $Grade;

		function IPChoice ( $ipListAll , $region ){
			$this->region = $region;
			$this->Grade = 0;
			$this->ipListAll = $ipListAll;
		}

		function countGrade(){
			
			// ­pºâ¨C­ÓIPªº¤À¼Æ
			for( $i = 0 ; $i < count($this->ipListAll) ; $i++ )
			{
				$iplist = $this->ipListAll[$i];
				//echo "debug". count($this->ipListAll) ."<br>";
				$A = $iplist->getA();
				$B = $iplist->getB();
				$C = $iplist->getC();
				//display(A+"&nbsp;"+B+"&nbsp;"+C);
				if ( $this->region < 7 )
				{
					$G = $A*(60-($this->region-1)*10) + 0.5*($B+$C)*(40+($this->region-1)*10);
				}else{
					$G = $B*60.0 + $C*40.0;
				}
				if ( $G >= 60 )
					echo $iplist->ip."<br>\n";
				//alert(G);
				if($G >= 60.0){
					//display("Can use:&nbsp;"+iplist.getIP());
					//alert("Can: "+iplist.getIP());
					$this->ipListCanRandom[] = $iplist;
				}
				if ( $G > $this->Grade )
					$this->Grade = $G;
			}
		}

		function getIPCanRandomList(){
			$temp = "";
			for( $i = 0 ; $i < count($this->ipListCanRandom) ; $i++ ){
				$ipcanrand = $this->ipListCanRandom[$i];
				$temp = $temp."IP ".($i+1).": ".$ipcanrand->getIP()."<br>";
			}
			return $temp;
		}
}

?>
