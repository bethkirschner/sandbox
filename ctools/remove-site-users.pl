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
my $CREATE_ARCHIVE_SQL = qq{
drop table ARCHIVE_SAKAI_SITE_USER;
drop table ARCHIVE_SAKAI_REALM_RL_GR;
create table ARCHIVE_SAKAI_SITE_USER (
    SITE_ID              VARCHAR2(99) NOT NULL,
    USER_ID              VARCHAR2(99) NOT NULL,
    PERMISSION           INTEGER NOT NULL );
create table ARCHIVE_SAKAI_REALM_RL_GR (
    REALM_KEY            INTEGER NOT NULL,
    USER_ID              VARCHAR2(99) NOT NULL,
    ROLE_KEY             INTEGER NOT NULL,
    ACTIVE               CHAR(1) NULL CHECK (ACTIVE IN (1, 0)),
    PROVIDED             CHAR(1) NULL CHECK (PROVIDED IN (1, 0)) );
};

my $ARCHIVE_USER_SQL = "insert into ARCHIVE_SAKAI_SITE_USER (select * from SAKAI_SITE_USER where site_id = 'SITE-ID');\n";
my $ARCHIVE_REALM_SQL = "insert into ARCHIVE_SAKAI_REALM_RL_GR (select * from SAKAI_REALM_RL_GR where realm_key in (select realm_key from sakai_realm where realm_id like '/site/SITE-ID%'));\n";

my $USER_SQL = "delete from SAKAI_SITE_USER where site_id = 'SITE-ID';\n";
my $REALM_SQL = "delete from SAKAI_REALM_RL_GR where realm_key in (select realm_key from sakai_realm where realm_id like '/site/SITE-ID%');\n";
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
   print OUTFILE $CREATE_ARCHIVE_SQL;
   
   SITE: foreach $_ (@sites)
   {
       chomp;
       next SITE if ( !$_ );
       my $sql;
       
       $sql = $ARCHIVE_USER_SQL;
       $sql =~ s/SITE-ID/$_/;
       print OUTFILE $sql;
       
       $sql = $USER_SQL;
       $sql =~ s/SITE-ID/$_/;
       print OUTFILE $sql;
       
       $sql = $ARCHIVE_REALM_SQL;
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
