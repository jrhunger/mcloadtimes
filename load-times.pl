#!/usr/bin/perl

# load dependencies
use WWW::Mechanize; 
use HTTP::Request::Common qw(POST);

$EMAIL='CHANGEME'; # replace with email used to login to MeetCentral (or use command-line option --email=user@domain
$PASS='CHANGEME';  # replace with password used to login to MeetCentral (or use command-line option --pass=mypassword)
$COURSE=0; # change default here or specify wiht --course=#

foreach $arg (@ARGV) {
  if ($arg =~ /--email=(.*)/) {
    $EMAIL=$1;
    next;
  }
  if ($arg =~ /--pass=(.*)/) {
    $PASS=$1;
    next;
  }
  if ($arg =~ /--course=([0-9])/) {
    $COURSE=$1;
    next;
  }
  if ($arg =~ /--debug/) {
    $DEBUG=1;
    next;
  }
  push @ARGS, $arg;
}

if (($EMAIL eq "CHANGEME")||($PASS eq "CHANGEME")) {
  die("no email/pass.  either edit the variables in the script or specify command line options --email=user\@domain.com --pass=mypass");
}

my $hydro = WWW::Mechanize->new();

sub login {
  $hydro->get("http://clubhouse.hydroxphere.com");
  $DEBUG && printf STDERR "--initial-page result\n%s\n", $hydro->content();

  $hydro->submit_form(with_fields => { 
    "email" => $EMAIL,
    "password" => $PASS,
  });
  $DEBUG && printf STDERR "--login result\n%s\n", $hydro->content();

  $hydro->follow_link("url"=>"http://clubhouse.hydroxphere.com/club/manageroster");
  $token = ($hydro->form_with_fields("_token"))->value("_token");
  $DEBUG && printf STDERR "--token = %s\n", $token;
  if (! $token) {
    print STDERR "login failed - returned content:\n";
    print STDERR $hydro->content();
    die("--login failed--");
  }
}

sub update_swimmer_time {
  my $swimmer_id = $_[0];
  my $distance = $_[1];
  my $stroke = $_[2];
  my $seconds = $_[3];
  my $course = $_[4];

  my $req = POST 'http://clubhouse.hydroxphere.com/club/getSwimmerBestTimeForCourse',
    [ '_token' => $token,
      'distance' => $distance,
      'stroke' => $stroke,
      'course' => $course,
      'swimmer_id' => $id,
    ];
  $hydro->request($req);
  if ($hydro->status() ne "200") {
    &log("getUpdateBestTimeView($id) status: " . $hydro->status());
  }
  printf STDERR "existing time: %s,%s,%s,%s = %s\n", $swimmer_id, $course, $stroke, $distance, $hydro->content();  
  
  $req = POST 'http://clubhouse.hydroxphere.com/club/updateSwimmerBestTimeForCourse',
    [ '_token' => $token,
      'distance' => $distance,
      'stroke' => $stroke,
      'course' => $course,
      'swimmer_id' => $swimmer_id,
      'seconds' => $seconds
    ];

  $hydro->request($req);
  if ($hydro->status() ne "200") {
    &log("non-success-status: " . $hydro->status());
    &log("id $id, distance $distance, stroke $stroke, seconds, $seconds");
  }
}

sub log {
  printf STDERR "$_[0]\n";
}

%strokenum = (
  "Free" => 1,
  "Back" => 2,
  "Breast" => 3,
  "Fly" => 4
);

&login();
open (LOAD, $ARGS[0]) || die("can't read '$ARGS[0]'.  Please specify file to load on command line as the final argument");
printf STDERR "reading $ARGS[0]\n";
while (my $line = <LOAD>) {
  chomp $line;
  @line = split(/	/, $line);
  $id = $line[4];
  if ($id !~ /^[0-9]+$/) {
    print STDERR "'$line' does not contain a swimmer id - skipping\n";
  }
  $time = $line[3];
  $line[2] =~ m/([0-9]+) ([A-Z][a-z]+)/;
  $distance = $1;
  $stroke = $2;
  &log($line);
  &log(sprintf "update_swimmer_time(%s, %s, %s, %s, %s)", $id, $distance, $strokenum{$stroke},&time2seconds($time), $COURSE);
  &update_swimmer_time(
    $id,
    $distance,
    $strokenum{$stroke},
    &time2seconds($time),
    $COURSE,
  );
}

sub time2seconds {
  my $time = $_[0];
  if ($time =~ /:/) {
    my @time = split(/:/, $time);
    return ($time[0]*60+$time[1]);
  }
  else {
    return $time;
  }
}
