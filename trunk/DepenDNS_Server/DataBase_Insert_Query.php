<html>
<head>
<title>Insert data to DataBase</title>
<script type="text/javascript"></script>
</head>
<body>
<form name="SelectForm" method="POST" action="DataBase_Insert_Query.php">
	<table>
		<tr>
			<td>Insert Domain Name:</td>
			<td><input type="text" name="DomainName" value="www.google.com"></td>
		</tr>
		<tr>
			<td>Resolve ip:</td>
			<td><input type="text" name="IP"></td>
		</tr>
		<tr>
			<td>Counter:</td>
			<td><input type="number" value = 1 name="Counter"></td>
		</tr>
		<tr align=center>
			<input name="Insert_or_Search" type="hidden" value="0">
			<td><input type="button" value="Search" name="Search" 
				onClick="this.form.Insert_or_Search.value='1';this.form.submit();" ></td>
			<td><input type="button" value="Insert" name="Insert" 
				onClick="this.form.Insert_or_Search.value='2';this.form.submit();"></td>
		</tr>
		<tr>
			<td colspan=2 align=center><input type="reset" value="clean"></td>
		</tr>
	</table>
<?php
if ( isset($_POST['DomainName']) && isset($_POST['IP']) && isset($_POST['Counter'])) {
	print "<script>
	this.SelectForm.DomainName.value='".$_POST['DomainName']."';
	this.SelectForm.IP.value='".$_POST['IP']."';
	this.SelectForm.Counter.value='".$_POST['Counter']."';
	</script>";
}
?>
</form>

<?php

if (isset($_POST['Insert_or_Search'])){
	if ($_POST['Insert_or_Search'] == 1){
		print "<h1>Search</h1>";
	} else if ($_POST['Insert_or_Search'] == 2){
		if ( strcmp($_POST['IP'],"") == 0 ){
			print "<p>Resolver IP is empty.</p>";
			exit();
		}
	} 
} else {
	exit();
}

require("dns.inc.php");

$DB_host = "localhost";
$DB_ID   = "dependns";
$DB_PWD  = "dependns@833";

if ( $_POST['DomainName'] != "" ){
	$question = $_POST['DomainName'];
} else {
	$question = "www.google.com";
}

$Config = parse_ini_file("dependns.ini",true);
$odbc_id = odbc_connect("dependns",$DB_ID,$DB_PWD);

if ($odbc_id) {
	// INSERT
	if ($_POST['Insert_or_Search'] == 2){
		$InsertIP = $_POST['IP'];
		$Counter = $_POST['Counter'];

		$sql_query = "SELECT id FROM domain_id WHERE domain_name = '".$question."';";
		$result = odbc_exec($odbc_id,$sql_query);
		if ( $result ){
			$row = odbc_fetch_array($result);
			if ( $row['id'] != null ){
				$id = $row['id'];
			} else {
				echo "<p>Insert $question to domain_id.</p>";
				$sql_query = "INSERT INTO domain_id (id,domain_name) VALUES( NULL , '".$question."');";
				odbc_exec($odbc_id,$sql_query);
				$sql_query = "SELECT id FROM domain_id WHERE domain_name = '".$question."';";
				$result = odbc_exec($odbc_id,$sql_query);
				$id = odbc_result($result,1);
			}
		} else {
			print "<p>Can't access database.</p>";
		}
		print "<p>Domain id of $questioin is $id</p>";

		$sql_query = "SELECT `index` FROM domain_DB WHERE domain_id='$id' and resolver='Tester' and ip='$InsertIP';";
		$result = odbc_exec($odbc_id,$sql_query);
		if ( $result ){
			$row = odbc_fetch_array($result);
			if ($row['index'] == null){
				print "Insert into domain_DB";
				$sql_query = "INSERT INTO domain_DB (domain_id,ip,resolver) VALUES('"
					.$id."','"
					.$InsertIP."','Tester');";
				odbc_exec($odbc_id,$sql_query);
			} else {
				print "Updat domain_db";
				$sql_query = "UPDATE domain_DB SET counter='$Counter' WHERE domain_id='$id'
					and ip='$InsertIP' and resolver='Tester';";
				odbc_exec($odbc_id,$sql_query);
			}
		} else {
			print "<p>Error in select index from domain_DB</p>";
		}

	} else if ($_POST['Insert_or_Search'] == 1){
		// Search 
		print "<p>Query $question...</p>";
		$sql_query = "SELECT id FROM domain_id WHERE domain_name = '".$question."';";
		$result = odbc_exec($odbc_id,$sql_query);
		if ( $result ){
			$row = odbc_fetch_array($result);
			if ( $row['id'] != null ){
				$id = $row['id'];
				$sql_query = "SELECT * FROM domain_DB WHERE domain_id = '$id';";
				$result = odbc_exec($odbc_id,$sql_query);
				if ($result){
					echo "<table border='1'>";
					echo "<tr>
						<th>ID</th>
						<th>IP</th>
						<th>Resolver</th>
						<th>Counter</th>
						</tr>";
					while ( $row = odbc_fetch_array($result) ){
						$ip     = $row['ip'];
						$resolver = $row['resolver'];
						$counter  = $row['counter'];
						echo "<tr>";
						echo "<th>$id</th>\n";
						echo "<th>$ip</th>\n";
						echo "<th>$resolver</th>\n";
						echo "<th>$counter</th>\n";
						echo "</tr>";
					}
					echo "</table>";
				}
			} else {
				print "<p>No such data in the Database.</p>";
			}
		} else {
			print "<p>Can't access database.</p>";
		}
	}
}

?>

</body>
</html>
