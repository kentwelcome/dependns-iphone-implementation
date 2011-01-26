#! /bin/perl -w
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request::Common qw(POST);

my $ua = new LWP::UserAgent;
my $url = "http://moon.cs.nthu.edu.tw/~kent/DepenDNS/dependns.php";

if ($#ARGV < 0){
	print "Usage: $0 <TargetURL>\n";
	exit(0);
}
my $ASK = $ARGV[0];
my $id  = "kent";
my $pwd = "123";

my $req = POST $url , Content => [ASK_URL => "$ASK" , User => "$id", Passwd => "$pwd"];
my $Response = $ua->request($req);
if ( $Response->is_success ){
	$Response->decode();
	my $de_content = $Response->content;
	print $de_content;
} else {
	print "Bad\n";
}
