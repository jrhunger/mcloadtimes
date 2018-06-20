# mcloadtimes

Perl script to load times into Meet Central

Usage:
load_times.pl {--email=user@domain.com} {--pass=mypassword} {--debug} file-name

You can edit the script and specify the email/password in there, or supply on the command line.
Using the --debug option will print out a bunch of the intermediate web pages it interacts with.

The file-name is mandatory, and currently this expects a tab-delimited file with the following fields:
1. First Last (not actually used, but helpful when creating the file in Excel, etc.)
2. gender M/F
3. distance 
4. Stroke (Free, Back, Breast, Fly)
5. Time in seconds
6. SwimmerID (this is the internal id for the swimmer in MeetCentral, not the one they write on their arm)

If the 6th field is not numeric, the line will be ignored so you can add a header row like:
First Last<tab>Gender<tab>Distance<tab>Stroke<tab>Time<tab>(Seconds)<tab>Swimmer ID

Dependencies:
- WWW::Mechanize (may have to be added on Linux, is included with Strawberry Perl on Windows)
- HTTP::Request::Common (I think this is a core perl module?)

