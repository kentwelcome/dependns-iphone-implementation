<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>DepenDNS</title>
<link rel=stylesheet type="text/css" href="NewStyle.css" media="screen">
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js" type="text/javascript" ></script>
<script>
function a(){
}

var isPhone = navigator.userAgent;
// match iPhone mobile device and android Phone
if ( isPhone.match(/iPhone/i) != null ){
	document.location.href="http://moon.cs.nthu.edu.tw/~kent/DepenDNS/DepenDNS/";
} else if ( isPhone.match(/Android/i) != null ){
	document.location.href="http://moon.cs.nthu.edu.tw/~kent/DepenDNS/DepenDNS/";
} 
</script>
</head>
<body>
<div id="outline">
	<img src="images/gradient.jpg" alt="" height="304" width="800" border="0" />
	<div id="title">
		<h3>DepenDNS</h3>
	</div>
</div>
<div id="content">
	<div id="register">
		<form name="login" method="post" action="index.php">
			<h1>Register for User ID</h1>
			<table width="20%" border="0" cellpadding="3" cellspacing="1" bgcolor="#FFFFFF" align:"center" style="margin-left:auto; margin-right:auto;">
				<tr>
					<td><p>Username:</p></td>
					<td><input name="userid" type="text" id="userid"></td>
				</tr>
				<tr>
					<td><p>E-Mail Address:</p></td>
					<td><input name="UserMail" type="text" id="UserMail"></td>
				</tr>
				<tr>

					<td><p>Password:</p></td>
					<td><input name="passwd" type="password" id="passwd"></td>
				</tr>
				<tr>
					<td><p>Re-enter Password:</p></td>
					<td><input name="check" type="password" id="check"></td>
				</tr>
				<tr>
					<td colspan=2>
<?php
require_once('recaptchalib.php');
$publickey = "6LdXtboSAAAAAIKFNyjWlp0NIcw-lkO3Tr_32AfA"; 
echo recaptcha_get_html($publickey);
?>
					</td>
					<tr>
						<td colspan=2><input type="submit" name="Submit" value="Submit"></td>
					</tr>
				</tr>
			</table>
		</form>


		<table width="100%" border="0" cellpadding="3" cellspacing="1" bgcolor="#FFFFFF" style="margin-left:auto; margin-right:auto;" >
<?php
require_once('recaptchalib.php');
$privatekey = "6LdXtboSAAAAAAo8kzeM0Ax99HX0jbCRDVRcXio9";
$resp = recaptcha_check_answer ($privatekey,
	$_SERVER["REMOTE_ADDR"],
	$_POST["recaptcha_challenge_field"],
	$_POST["recaptcha_response_field"]);

if ( !$resp->is_valid ) {
	//die ("The reCAPTCHA wasn't entered correctly. Go back and try it again."."(reCAPTCHA said: " . $resp->error . ")");
	if ( $_POST['userid'] ){
		echo "<tr><td><h2>Enter reCAPTCHA again, please.</h2></td></tr>";
	}
} else {
	$passwd 	= $_POST["passwd"];
	$again 		= $_POST["check"];
	$userid 	= $_POST["userid"];
	$UserMail 	= $_POST["UserMail"];

	if ( $passwd == $again ){
		$link = mysql_connect("localhost", "dependns", "dependns@833");
		if ( mysql_select_db("dependns", $link) ){
			$sql_query = "select UserInfo.username from UserInfo where UserInfo.username = '".$userid."';";
			$result = mysql_query($sql_query);
			$row = mysql_fetch_array($result);

			// no such ID
			if ( !$row['username'] ){
				$MD5_hash = md5($passwd);
				$sql_query = "insert into UserInfo (username,passwd,MailAddress) values('".$userid."','".$MD5_hash."','".$UserMail."');";
				$result = mysql_query($sql_query);
				echo "<tr><td><h2>Registration Completed!</h2></td></tr>";
			} else {
				echo"<tr><td><h2>error</h2></td></tr>";
			}
		}
	} else {
		echo "<tr><td><h2>Password Error!</h2></td></tr>";
	}
}
?>	
		</table>
	</div>
</div>

<div id="footer">
</div>

</body>
</html>
