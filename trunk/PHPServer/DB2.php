<?

$database = '140.114.88.45';
$user = 'CS4710';
$password = 'CS4710';

$conn = db2_connect($database, $user, $password);

if ($conn) {
	echo "Connection succeeded.";
	db2_close($conn);
}
else {
	echo "Connection failed.";
}

?>
