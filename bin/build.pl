#########################################################################
#########################################################################
#
# A convenience wrapper around ant.  Simplifies the input args.
#
#########################################################################
#########################################################################


use strict;
use Cwd 'realpath'; 

my @whats = ("install", "webinstall");

my $projectHome = $ENV{PROJECT_HOME};
my $gusConfigFile = $ENV{GUS_HOME} . "/config/gus.config";

if (!$projectHome) {
  if (! (-e "build.pl" && -d "../install")) {
    print "Error: Please either define the \$PROJECT_HOME environment variable or run install from the install/ directory\n";
    exit 1;
  }
  $projectHome = realpath("..");
} 

my ($project, $component, $doWhat, $targetDir, $append, $clean, 
    $installDBSchema, $doCheckout, $tag, $webPropFile, $returnErrStatus, $installConfigFile) = &parseArgs(@ARGV);

# set local maven repo to user's env var if available, else use $HOME/.m2/repository
my $mvnRepo = ( "$ENV{M2_REPO}" eq "" ? "$ENV{HOME}/.m2/repository" : "$ENV{M2_REPO}" );
print STDERR "Maven local repository set to: $mvnRepo\n";

$| = 1;

my $cmd = "ant -f $projectHome/install/build.xml $doWhat -lib $projectHome/install/config -Dproj=$project -DtargetDir=$targetDir -Dcomp=\"$component\" -DgusConfigFile=$gusConfigFile -DprojectsDir=$projectHome -DmvnRepo=$mvnRepo $clean $installDBSchema $append $webPropFile $tag $installConfigFile -logger org.apache.tools.ant.NoBannerLogger ";

# if not returning error status, then can pretty up output by keeping
# only lines with bracketed ant target name (ie, ditch its commentary).
# the grep, however, frustrates accurate status reporting
#if (!$returnErrStatus) {
#   $cmd .= " | grep ']' | grep -v chmod";
#}

# print "\n$cmd\n\n";
system($cmd);

# only valid if $returnErrStatus is set
my $status = $? >>8;
exit($status);


############################ subroutines ####################################

sub parseArgs {

    my $project = shift @ARGV;
    my $component; 

    if ($project =~ /([\w-]+)(\/\w+)/ ) {
        $project = $1;
        $component = $2;
    }
    my $doWhat = shift @ARGV;

    if ($doWhat eq "release") {
      &usage unless (scalar(@ARGV) == 1);
      my $tag = "-Dtag=$ARGV[0]";
      return ($project, '', $doWhat, '', '', '', '', '', $tag);
    }

    my $targetDir;
    if ($ENV{GUS_HOME} && (!$ARGV[0] || $ARGV[0] =~ /^-/)) {
        $targetDir = $ENV{GUS_HOME};
    } else {
        $targetDir = shift @ARGV;
    }

    &usage() unless $project;
    &usage("unknown subcommand '$doWhat'") unless $doWhat && grep(/$doWhat/, (@whats, "release"));
    &usage("targetDir not defined") unless $targetDir;


    my ($append, $clean, $installDBSchema, $doCheckout, $version, $webPropFile, $installConfigFile);
    if ($ARGV[0] eq "-append") {
        shift @ARGV;
        $append = "-Dappend=true";
    } 

    if ($ARGV[0] eq "-clean") {
        shift @ARGV;
        $clean = "-Dclean=true";
    }
   
    if ($ARGV[0] eq "-returnErrStatus") {
        shift @ARGV;
        $returnErrStatus = 1;
    }
   
    if ($ARGV[0] eq "-installConfigFile") {
        shift @ARGV;
        $installConfigFile = "-DinstallConfigFile=true";
    }

    if ($ARGV[0] eq "-installDBSchema") {
        &usage("--installConfigFile not allowed with --installDBSchema") if ($installConfigFile);
        shift @ARGV;
        $installDBSchema = "-DinstallDBSchema=true";
    }

    if ($ARGV[0] eq "-installDBSchemaSkipRoles") {
        shift @ARGV;
        $installDBSchema = "-DinstallDBSchema=true -DskipRoles=true";
    }

    if ($ARGV[0] eq "-webPropFile") {
        shift @ARGV;
        my $wpFile = shift @ARGV;
        if (!-e $wpFile) { 
            print "Error: webPropFile not found\n"; 
            exit 1; 
        }
        $webPropFile = "-propertyfile $wpFile -DwebPropFile=$wpFile";
    }

    if ($doCheckout = $ARGV[0]) {
        &usage("") if ($doCheckout ne "-co");
        $version = $ARGV[1];
    }

    return ($project, $component, $doWhat, $targetDir, $append, $clean, $installDBSchema, $doCheckout, $version, $webPropFile, $returnErrStatus, $installConfigFile);
}

sub usage {
    my ($error) = @_;
    print "\nFATAL: $error\n" if ($error);
    my $whats = join("|", @whats);

    print 
"
usage: 
  build projectname\[/componentname]  $whats -append [-installConfigFile] [-installDBSchema | -installDBSchemaSkipRoles] [-webPropFile propfile] [-co [version]]
  build projectname release version

";
    exit 1;
}


