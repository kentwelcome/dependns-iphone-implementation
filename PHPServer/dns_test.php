<? // simple DNS query example

require("dns.inc.php"); // Require API Source
$dns_server="ns.somehost.com"; // Our DNS Server

$dns_query=new DNSQuery($dns_server); // create DNS Query object - there are other options we could pass here

$question="www.somehost.com"; // the question we will ask
$type="A"; // the type of response(s) we want for this question

$result=$dns_query->Query($question,$type); // do the query 

// Trap Errors

if ( ($result===false) || ($dns_query->error!=0) ) // error occured
  {
  echo $dns_query->lasterror;
  exit();
  }


//Process Results

$result_count=$result->count; // number of results returned

for ($a=0; $a<$result_count; $a++)
  {
  if ($result->results[$a]->typeid=="A") // only after A records
    {     echo $question." has IP address ".$result->results[$a]->data."<br>";
    echo $result->results[$a]->string."<br>";
    }
  }

?>
