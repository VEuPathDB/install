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
    
    # should be checkout command, the url must be present
    my $url = shift @ARGV;
    my $svnurl = "-Dtopsvnurl=$url";

    &usage() unless $project;
    &usage() unless $doWhat && grep(/$doWhat/, (@whats));
    &usage() unless $svnurl;
    
    my ($branch, $version);

    if ($ARGV[0] eq "-branch") {
	shift @ARGV;
        $branch = "-Dbranch=true";
        my $ver = shift @ARGV;
        if ($ver) {
            $version = "-Dvers=$ver";
            shift @ARGV;
            &usage() unless $version;
        }
    } 

    return ($project, $doWhat, $branch, $version, $svnurl);
}

sub usage {
    my $whats = join("|", @whats);

    print 
"
Checkout or update a top-level project, either the trunk or a branch.

gussvn is \"smart\" in that it recursively follows the project dependency
structure as defined in the build.xml files.  If you give it a project,
it will find the projects it depends on, recursively.  It also obeys the
version information in the build.xml files.  This way, you can have it find
all depended upon projects within a branch.

Usage:
  gussvn <projectname> checkout <svnurl> [-branch <version>]
  gussvn <projectname> update

Where:
  projectname:  is the name of a project that you have already checked out.
  checkout:     use this option to do a svn checkout
  update:       use this option to do a svn update
  svnurl:       the location in the svn repository of the top-level project, but  stopping
                before /branches or /trunk (see Examples).
  -branch:      use this option to check out from a branch
  version:      the name of the branch to check out (ie, the name after /branches/ in an svn url)

Examples:
    gussvn PlasmoDBWebsite checkout https://www.cbil.upenn.edu/svn/apidb/PlasmoDBWebsite
    gussvn PlasmoDBWebsite checkout https://www.cbil.upenn.edu/svn/apidb/PlasmoDBWebsite -branch plasmodb5.0beta
    gussvn PlasmoDBWebsite update
  
";
    exit 1;
}


