<html>
<title>
	Dependns Regist Web Page
</title>
<body>
<form name="login" method="post" action="check.php">
	<td>
		<table width="20%" border="0" cellpadding="3" cellspacing="1" bgcolor="#FFFFFF">
			<tr>
				<td colspan="3"><strong>Regist User ID</strong></td>
			</tr>
			<tr>
				<td>Username:<br>
					<input name="userid" type="text" id="userid"></td>
			</tr>
			<tr>

				<td>Password:<br>
					<input name="passwd" type="password" id="passwd"></td>
			</tr>
			<tr>
				<td>Again<br>
					<input name="check" type="password" id="check"></td>
			</tr>
			<tr>
				<td>
<?
require_once('recaptchalib.php');
$publickey = "6LdXtboSAAAAAIKFNyjWlp0NIcw-lkO3Tr_32AfA"; 
echo recaptcha_get_html($publickey);
?>
				</td>
				<tr>
					<td><input type="submit" name="Submit" value="Submit"></td>
				</tr>
				<td>&nbsp;</td>
			</tr>
		</table>
	</td>
</form>


<table width="20%" border="0" cellpadding="3" cellspacing="1" bgcolor="#FFFFFF">
	<tr>
<?
require_once('recaptchalib.php');
$privatekey = "6LdXtboSAAAAAAo8kzeM0Ax99HX0jbCRDVRcXio9";
$resp = recaptcha_check_answer ($privatekey,
	$_SERVER["REMOTE_ADDR"],
	$_POST["recaptcha_challenge_field"],
	$_POST["recaptcha_response_field"]);

if (!$resp->is_valid ) {
	//die ("The reCAPTCHA wasn't entered correctly. Go back and try it again."."(reCAPTCHA said: " . $resp->error . ")");
} else {
	$passwd = $_POST["passwd"];
	$again = $_POST["check"];
	$userid = $_POST["userid"];

	if ( $passwd == $again ){
		$link = mysql_connect("localhost", "dependns", "dependns@833");
		if ( mysql_select_db("dependns", $link) ){
			$mysql_query = "select UserInfo from UserInfo where UserInfo.username ='".$userid."';";
			$result = mysql_query($sql_query);

			// no such ID
			if ( !$result ){
				$MD5_hash = md5($passwd);
				$sql_query = "insert into UserInfo (username,passwd) values('".$userid."','".$MD5_hash."');";
				$result = mysql_query($sql_query);
				echo "<td>Regist Success!</td>";
				exit(1);
			}
		}
	} else {
		echo "<td>Password Error!</td>";
	}
}
?>	
	</tr>
</table>

</body>
</html>
