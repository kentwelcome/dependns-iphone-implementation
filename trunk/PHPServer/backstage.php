<html>
<head>
<title>DepenDNS White List Selecting Page.</title>
<script>
function post_to_url(path, params, method) {
	method = method || "post"; // Set method to post by default, if not specified.

	// The rest of this code assumes you are not using a library.
	// It can be made less wordy if you use one.
	var form = document.createElement("form");
	form.setAttribute("method", method);
	form.setAttribute("action", path);

	for(var key in params) {
		var hiddenField = document.createElement("input");
		hiddenField.setAttribute("type", "hidden");
		hiddenField.setAttribute("name", key);
		hiddenField.setAttribute("value", params[key]);

		form.appendChild(hiddenField);
	}

	document.body.appendChild(form);    // Not entirely sure if this is necessary
	form.submit();
}

function FormCheck(theForm){
	if (theForm.AddNew.value == ""){
		theForm.AddNew.focus();
		return(false);
	}
	return(true);
}


</script>
</head>
<body>
<center><h1>White List</h1></center>
<div id="WriteList">
<?php
// read configure file from dependns.ini
$Config = parse_ini_file("dependns.ini",true);

// check history database
// db link
if ( $Config['DataBase'] ) { 
	$DB_host = $Config['DataBase']['SQL_Server'];
	$DB_ID   = $Config['DataBase']['SQL_ID'];
	$DB_PWD  = $Config['DataBase']['SQL_PWD'];


} else {
	$DB_host = "localhost";
	$DB_ID	 = "dependns";
	$DB_PWD	 = "dependns@833";
}

$odbc_id = odbc_connect("dependns",$DB_ID,$DB_PWD);
if (!$odbc_id){
	print "<h1>Data Base Down!</h1>";
	exit();
}

if (isset($_POST['Delete'])){
	$DeleteID = $_POST['Delete'];
	//print "<p>Delete $DeleteID</p>";
	$SQL = "DELETE FROM WhiteList WHERE domain_id = '$DeleteID'";
	odbc_exec($odbc_id,$SQL);
}

if (isset($_POST['AddNew'])){
	$AddNew = $_POST['AddNew'];
	$SQL = "SELECT id FROM domain_id WHERE domain_name = '$AddNew'";
	$result = odbc_exec($odbc_id,$SQL);
	$row = odbc_fetch_array($result);
	if ( $row['id'] == NULL ){
		print "<p>No such domain ($AddNew) in the database</p>";
		//goto DisplayList;
	} else {
		$ID = $row['id'];
	}
	$SQL = "SELECT domain_id FROM WhiteList WHERE domain_id = '$ID'";
	$result = odbc_exec($odbc_id,$SQL);
	$row = odbc_fetch_array($result);
	if ( $row['domain_id'] != NULL ){
		print "<p>The domain ($AddNew) is already in the White List</p>";
	} else {
		$SQL = "INSERT INTO WhiteList (domain_id) VALUES ('$ID')";
		odbc_exec($odbc_id,$SQL);
	}

}

//DisplayList:
$SQL = "SELECT domain_id.domain_name , domain_id.id FROM domain_id, WhiteList WHERE domain_id.id = WhiteList.domain_id";
$result = odbc_exec($odbc_id,$SQL);

print "<h3>Current White List</h3>";
print "<table>";
while ( $row = odbc_fetch_array($result)){
	print "<tr>";
	print "<td>".$row['domain_name']."</td>";
	print "<td><input type='button' name='".$row['id']."' value='remove' onclick=\"post_to_url('backstage.php',{'Delete':'".$row['id']."'})\"></td>";
	print "</tr>";
}
print "</table>";
?>
</div>
<div id="AddDomain">
<h3>Add Domain To White List</h3>
<form method="POST" id="AddWhiteList" onSubmit="if(FormCheck(this)){return true;}else{return false;}">
<?php
if (isset($AddNew)){
	print "Insert:<input type='text' id='AddNew' name='AddNew' value='$AddNew'/>";
} else {
	print "Insert:<input type='text' id='AddNew' name='AddNew' />";
}
?>
<input type="submit" />
</form>
</div>
</body>
</html>

