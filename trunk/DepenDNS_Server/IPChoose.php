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
			
			// All the IPs from resolvers
			for( $i = 0 ; $i < count($this->ipListAll) ; $i++ )
			{
				$iplist = $this->ipListAll[$i];
				// Get the grade 
				$A = $iplist->getA();
				$B = $iplist->getB();
				$C = $iplist->getC();
				//display(A+"&nbsp;"+B+"&nbsp;"+C);

				// Calculate the grade
				if ( $this->region < 7 )
				{
					$G = $A*(60-($this->region-1)*10) + 0.5*($B+$C)*(40+($this->region-1)*10);
				}else{
					$G = $B*60.0 + $C*40.0;
				}

				// The results are secure
				if ( $G >= 60 ) {
					echo $iplist->ip."<br>\n";
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
