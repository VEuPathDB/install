#########################################################################
#########################################################################
#
# A convenience wrapper around ant.  Simplifies the input args.
#
#########################################################################
#########################################################################


use strict;
use Cwd 'realpath'; 

my @projects = ("AllGenes", "AnnotatorsInterface", "Annotator", "CBIL", "DJob", "DoTS", "GUS", "ParaDBs", "PlasmoDB","RAD","ApiDots");

my @whats = ("install", "webinstall");

my $projectHome = $ENV{PROJECT_HOME};

if (!$projectHome) {
  if (! (-e "build.pl" && -d "../install")) {
    print "Error: Please either define the \$PROJECT_HOME environment variable or run install from the install/ directory\n";
    exit 1;
  }
  $projectHome = realpath("..");
} 

my ($project, $component, $doWhat, $targetDir, $append, $clean, $doCheckout, $tag, $webPropFile) = &parseArgs(@ARGV);

$| = 1;

my $cmd = "ant -f $projectHome/install/build.xml $doWhat -Dproj=$project -DtargetDir=$targetDir -Dcomp=$component -DprojectsDir=$projectHome $clean $append $webPropFile $tag -logger org.apache.tools.ant.NoBannerLogger | grep ']'";

print "\n$cmd\n\n";
system($cmd);



############################ subroutines ####################################

sub parseArgs {

    my $project = shift @ARGV;
    my $component; 

    if ($project =~ /(\w+)(\/\w+)/ ) {
	$project = $1;
	$component = $2;
    }
    my $doWhat = shift @ARGV;

    if ($doWhat eq "release") {
      &usage unless (scalar(@ARGV) == 1);
      my $tag = "-Dtag=$ARGV[0]";
      return ($project, '', $doWhat, '', '', '', '', $tag);
    }

    my $targetDir;
    if ($ENV{GUS_HOME} && (!$ARGV[0] || $ARGV[0] =~ /^-/)) {
	$targetDir = $ENV{GUS_HOME};
    } else {
	$targetDir = shift @ARGV;
    }

    &usage() unless $project && grep(/$project/, @projects);
    &usage() unless $doWhat && grep(/$doWhat/, (@whats, "release"));
    &usage() unless $targetDir;


    my ($append, $clean, $doCheckout, $version, $webPropFile);
    if ($ARGV[0] eq "-append") {
	shift @ARGV;
        $append = "-Dappend=true";
    } 

    if ($ARGV[0] eq "-clean") {
        shift @ARGV;
        $clean = "-Dclean=true";
    }
   
    if ($ARGV[0] eq "-webPropFile") {
        shift @ARGV;
	my $wpFile = shift @ARGV;
	$webPropFile = "-propertyfile $wpFile -DwebPropFile=$wpFile";
    }

    if ($doCheckout = $ARGV[0]) {
	&usage() if ($doCheckout ne "-co");
	$version = $ARGV[1];
    }

    return ($project, $component, $doWhat, $targetDir, $append, $clean, $doCheckout, $version, $webPropFile);
}

sub usage {
    my $projects = join("|", @projects);
    my $whats = join("|", @whats);

    print 
"
usage: 
  build $projects\[/componentname]  $whats  targetDir -append [-webPropFile propfile] [-co [version]] 
  build $projects release version

";
    exit 1;
}


