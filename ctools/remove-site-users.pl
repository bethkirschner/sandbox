#!/usr/bin/perl
#
# Generates SQL to remove all CTools users from specified sites
#
# remove-site-users.pl: {site-id-file} {output-file}
#
#      site-id-file : text file of specified site-ids (each on separate line)
#      output-file  : SQL file to be executed
# 

use strict;

my $USER_SQL = "delete from SAKAI_SITE_USER where site_id = 'SITE-ID';\n";
my $REALM_SQL = "delete from sakai_realm_rl_gr where realm_key in (select realm_key from sakai_realm where realm_id like '/site/SITE-ID%');\n";
my $COMMIT_SQL = "commit;\n";

main:
{
   if ( $#ARGV != 1 )
   {
       print " remove-site-users.pl: {site-id-file} {output-file}\n";
       exit -1;
   }

   ## set up default values
   my $inFile  = $ARGV[0];
   my $outFile = $ARGV[1];
   
   open INFILE, $inFile or die "$!";
   my @sites = <INFILE>;
   close INFILE;

   open OUTFILE, "> $outFile" or die "$!";
   SITE: foreach $_ (@sites)
   {
       chomp;
       next SITE if ( !$_ );
       
       my $sql = $USER_SQL;
       $sql =~ s/SITE-ID/$_/;
       print OUTFILE $sql;
       
       $sql = $REALM_SQL;
       $sql =~ s/SITE-ID/$_/;
       print OUTFILE $sql;
   }
   print OUTFILE $COMMIT_SQL;
   close OUTFILE;
   
   print "\n\n...Finished...\n\n";  
}
