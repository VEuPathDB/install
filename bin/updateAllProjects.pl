foreach $dir (glob "$ENV{PROJECT_HOME}/*") {
  next unless -d "$dir/CVS";
  print STDERR "\nUpdating $dir\n";
  chdir $dir;
  system("cvs update -d") && die "\nFailed running cvs update -d in $dir. \n\nPerhaps you have a conflict in one of the files that was merged (look for a 'C' to the left of a file.  If so, edit that file, and search for '<<<<' which marks the start of the conflict(s))\n";
  chdir $ENV{PROJECT_HOME};
}
