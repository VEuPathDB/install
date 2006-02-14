#########################################################################
#########################################################################
#
# A convenience wrapper around ant.  Simplifies the input args.
#
#########################################################################
#########################################################################


use strict;
use Cwd 'realpath'; 

my @whats = ("checkout", "update");

my $projectHome = $ENV{PROJECT_HOME};

if (!$projectHome) {
  if (! (-e "gussvn.pl" && -d "../install")) {
    print "Error: Please either define the \$PROJECT_HOME environment variable or run install from the install/ directory\n";
    exit 1;
  }
  $projectHome = realpath("..");
} 

my ($project, $doWhat, $branch, $version, $svnurl) = &parseArgs(@ARGV);

$| = 1;

my $cmd = "ant -f $projectHome/install/build.xml $doWhat -lib $projectHome/install/config -Dproj=$project -DprojectsDir=$projectHome $svnurl $branch $version -logger org.apache.tools.ant.NoBannerLogger ";


# if not returning error status, then can pretty up output by keeping
# only lines with bracketed ant target name (ie, ditch its commentary).
# the grep, however, frustrates accurate status reporting
#if (!$returnErrStatus) {
#  $cmd .= " | grep ']'";
#}

# print "\n$cmd\n\n";
system($cmd);

# only valid if $returnErrStatus is set
my $status = $? >>8;
exit($status);


############################ subroutines ####################################

sub parseArgs {

    my $project = shift @ARGV;
    if ($project =~ /([\w-]+)(\/\w+)/ ) {
	$project = $1;
    }
    
    my $doWhat = shift @ARGV;

    if ($doWhat eq "update") {
      &usage unless (scalar(@ARGV) == 0);
      return ($project, $doWhat, '', '', '');
    }
    
    print "Passed update.";
    
    # should be checkout command, the url must be present
    my $svnurl = shift @ARGV;

    &usage() unless $project;
    &usage() unless $doWhat && grep(/$doWhat/, (@whats));
    &usage() unless $svnurl;
    
    my ($branch, $version);

    if ($ARGV[0] eq "-branch") {
	shift @ARGV;
        $branch = "-Dbranch=true";
        my $ver = shift @ARGV;
        if ($ver) {
            $version = "-Dversion=$ver";
            shift @ARGV;
        }
    } 

    return ($project, $doWhat, $branch, $version, $svnurl);
}

sub usage {
    my $whats = join("|", @whats);

    print 
"
usage: 
  build projectname checkout svnurl [-branch [version]] 
  build projectname update

";
    exit 1;
}


