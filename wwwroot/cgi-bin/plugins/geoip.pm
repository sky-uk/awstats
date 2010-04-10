#!/usr/bin/perl
#-----------------------------------------------------------------------------
# GeoIp Maxmind AWStats plugin
# This plugin allow you to get country report with countries detected
# from a Geographical database (GeoIP internal database) instead of domain
# hostname suffix.
# Need the country database from Maxmind (free).
#-----------------------------------------------------------------------------
# Perl Required Modules: Geo::IP or Geo::IP::PurePerl
#-----------------------------------------------------------------------------
# $Revision$ - $Author$ - $Date$


# <-----
# ENTER HERE THE USE COMMAND FOR ALL REQUIRED PERL MODULES
use vars qw/ $type /;
$type='geoip';
if (!eval ('require "Geo/IP.pm";')) {
	$error1=$@;
	$type='geoippureperl';
	if (!eval ('require "Geo/IP/PurePerl.pm";')) {
		$error2=$@;
		$ret=($error1||$error2)?"Error:\n$error1$error2":"";
		$ret.="Error: Need Perl module Geo::IP or Geo::IP::PurePerl";
		return $ret;
	}
}
# ----->
#use strict;
no strict "refs";



#-----------------------------------------------------------------------------
# PLUGIN VARIABLES
#-----------------------------------------------------------------------------
# <-----
# ENTER HERE THE MINIMUM AWSTATS VERSION REQUIRED BY YOUR PLUGIN
# AND THE NAME OF ALL FUNCTIONS THE PLUGIN MANAGE.
my $PluginNeedAWStatsVersion="5.4";
my $PluginHooksFunctions="GetCountryCodeByAddr GetCountryCodeByName ShowInfoHost";
my $PluginName = "geoip";
my $LoadedOverride=0;
my $OverrideFile="";
my %TmpDomainLookup;
# ----->

# <-----
# IF YOUR PLUGIN NEED GLOBAL VARIABLES, THEY MUST BE DECLARED HERE.
use vars qw/
$gi
/;
# ----->


#-----------------------------------------------------------------------------
# PLUGIN FUNCTION: Init_pluginname
#-----------------------------------------------------------------------------
sub Init_geoip {
	my $InitParams=shift;
	my $checkversion=&Check_Plugin_Version($PluginNeedAWStatsVersion);

	# <-----
	# ENTER HERE CODE TO DO INIT PLUGIN ACTIONS
	debug(" Plugin $PluginName: InitParams=$InitParams",1);
   	my ($mode,$datafile,$override)=split(/\s+/,$InitParams,3);
   	if (! $datafile) { $datafile="$PluginName.dat"; }
	if ($type eq 'geoippureperl') {
		if ($mode eq '' || $mode eq 'GEOIP_MEMORY_CACHE')  { $mode=Geo::IP::PurePerl::GEOIP_MEMORY_CACHE(); }
		else { $mode=Geo::IP::PurePerl::GEOIP_STANDARD(); }
	} else {
		if ($mode eq '' || $mode eq 'GEOIP_MEMORY_CACHE')  { $mode=Geo::IP::GEOIP_MEMORY_CACHE(); }
		else { $mode=Geo::IP::GEOIP_STANDARD(); }
	}
	if ($override){$OverrideFile=$override;}
	%TmpDomainLookup=();
	debug(" Plugin $PluginName: GeoIP initialized type=$type mode=$mode override=$override",1);
	if ($type eq 'geoippureperl') {
		$gi = Geo::IP::PurePerl->open($datafile, $mode);
	} else {
		$gi = Geo::IP->open($datafile, $mode);
	}

# Fails on some GeoIP version
# 	debug(" Plugin geoip: GeoIP initialized database_info=".$gi->database_info());
	# ----->

	return ($checkversion?$checkversion:"$PluginHooksFunctions");
}


#-----------------------------------------------------------------------------
# PLUGIN FUNCTION: GetCountryCodeByAddr_pluginname
# UNIQUE: YES (Only one plugin using this function can be loaded)
# GetCountryCodeByAddr is called to translate an ip into a country code in lower case.
#-----------------------------------------------------------------------------
sub GetCountryCodeByAddr_geoip {
    my $param="$_[0]";
	# <-----
	if (! $param) { return ''; }
	if (!$LoadedOverride){&LoadOverrideFile_geoip();}
	my $res=$TmpDomainLookup{$param}||'';
	if (! $res) {
		$res=lc($gi->country_code_by_addr($param)) || 'unknown';
		$TmpDomainLookup{$param}=$res;
		if ($Debug) { debug("  Plugin $PluginName: GetCountryCodeByAddr for $param: [$res]",5); }
	}
	elsif ($Debug) { debug("  Plugin $PluginName: GetCountryCodeByAddr for $param: Already resolved to [$res]",5); }
	# ----->
	return $res;
}


#-----------------------------------------------------------------------------
# PLUGIN FUNCTION: GetCountryCodeByName_pluginname
# UNIQUE: YES (Only one plugin using this function can be loaded)
# GetCountryCodeByName is called to translate a host name into a country code in lower case.
#-----------------------------------------------------------------------------
sub GetCountryCodeByName_geoip {
    my $param="$_[0]";
	# <-----
	if (! $param) { return ''; }
	if (!$LoadedOverride){&LoadOverrideFile_geoip();}
	my $res=$TmpDomainLookup{$param}||'';
	if (! $res) {
		$res=lc($gi->country_code_by_name($param)) || 'unknown';
		$TmpDomainLookup{$param}=$res;
		if ($Debug) { debug("  Plugin $PluginName: GetCountryCodeByName for $param: [$res]",5); }
	}
	elsif ($Debug) { debug("  Plugin $PluginName: GetCountryCodeByName for $param: Already resolved to [$res]",5); }
	# ----->
	return $res;
}


#-----------------------------------------------------------------------------
# PLUGIN FUNCTION: ShowInfoHost_pluginname
# UNIQUE: NO (Several plugins using this function can be loaded)
# Function called to add additionnal columns to the Hosts report.
# This function is called when building rows of the report (One call for each
# row). So it allows you to add a column in report, for example with code :
#   print "<TD>This is a new cell for $param</TD>";
# Parameters: Host name or ip
#-----------------------------------------------------------------------------
sub ShowInfoHost_geoip {
    my $param="$_[0]";
	# <-----
	if ($param eq '__title__') {
    	my $NewLinkParams=${QueryString};
    	$NewLinkParams =~ s/(^|&)update(=\w*|$)//i;
    	$NewLinkParams =~ s/(^|&)output(=\w*|$)//i;
    	$NewLinkParams =~ s/(^|&)staticlinks(=\w*|$)//i;
    	$NewLinkParams =~ s/(^|&)framename=[^&]*//i;
    	my $NewLinkTarget='';
    	if ($DetailedReportsOnNewWindows) { $NewLinkTarget=" target=\"awstatsbis\""; }
    	if (($FrameName eq 'mainleft' || $FrameName eq 'mainright') && $DetailedReportsOnNewWindows < 2) {
    		$NewLinkParams.="&framename=mainright";
    		$NewLinkTarget=" target=\"mainright\"";
    	}
    	$NewLinkParams =~ tr/&/&/s; $NewLinkParams =~ s/^&//; $NewLinkParams =~ s/&$//;
    	if ($NewLinkParams) { $NewLinkParams="${NewLinkParams}&"; }

		print "<th width=\"80\">";
        print "<a href=\"#countries\">GeoIP<br />Country</a>";
        print "</th>";
	}
	elsif ($param) {
		# try loading our override file if we haven't yet
		if (!$LoadedOverride){&LoadOverrideFile_geoip();}
        my $ip=0;
		my $key;
		if ($param =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {	# IPv4 address
		    $ip=4;
			$key=$param;
		}
		elsif ($param =~ /^[0-9A-F]*:/i) {						# IPv6 address
		    $ip=6;
			$key=$param;
		}
		print "<td>";
		if ($key && $ip==4) {
			my $res = $TmpDomainLookup{$param}||'';
        	if (!$res){$res=lc($gi->country_code_by_addr($param)) if $gi;}
        	if ($Debug) { debug("  Plugin $PluginName: GetCountryByIp for $param: [$res]",5); }
		    if ($res) { print $DomainsHashIDLib{$res}?$DomainsHashIDLib{$res}:"<span style=\"color: #$color_other\">$Message[0]</span>"; }
		    else { print "<span style=\"color: #$color_other\">$Message[0]</span>"; }
		}
		if ($key && $ip==6) {
		    print "<span style=\"color: #$color_other\">$Message[0]</span>";
		}
		if (! $key) {
        	my $res = $TmpDomainLookup{$param}||'';
        	if (!$res){$res=lc($gi->country_code_by_addr($param)) if $gi;}
        	if ($Debug) { debug("  Plugin $PluginName: GetCountryByHostname for $param: [$res]",5); }
		    if ($res) { print $DomainsHashIDLib{$res}?$DomainsHashIDLib{$res}:"<span style=\"color: #$color_other\">$Message[0]</span>"; }
		    else { print "<span style=\"color: #$color_other\">$Message[0]</span>"; }
		}
		print "</td>";
	}
	else {
		print "<td>&nbsp;</td>";
	}
	return 1;
	# ----->
}

#-----------------------------------------------------------------------------
# PLUGIN FUNCTION: LoadOverrideFile
# Attempts to load a comma delimited file that will override the GeoIP database
# Useful for Intranet records
# CSV format: IP,2-char Country code
#-----------------------------------------------------------------------------
sub LoadOverrideFile_geoip{
	my $filetoload="";
	if ($OverrideFile){
		if (!open(GEOIPFILE, $OverrideFile)){
			debug("Plugin $PluginName: Unable to open override file: $OverrideFile");
			$LoadedOverride = 1;
			return;
		}
	}else{
		my $conf = (exists(&Get_Config_Name) ? Get_Config_Name() : $SiteConfig);
		if ($conf && open(GEOIPFILE,"$DirData/$PluginName.$conf.txt"))	{ $filetoload="$DirData/$PluginName.$conf.txt"; }
		elsif (open(GEOIPFILE,"$DirData/$PluginName.txt"))	{ $filetoload="$DirData/$PluginName.txt"; }
		else { debug("Did not find $PluginName file \"$DirData/$PluginName.txt\": $!"); }
	}
	# This is the fastest way to load with regexp that I know
	while (<GEOIPFILE>){
		chomp $_;
		s/\r//;
		my @record = split(",", $_);
		# replace quotes if they were used in the file
		foreach (@record){ $_ =~ s/"//g; }
		# store in hash
		$TmpDomainLookup{$record[0]} = $record[1];
	}
	close GEOIPFILE;
	$LoadedOverride = 1;
	debug(" Plugin $PluginName: Overload file loaded: ".(scalar keys %TmpDomainLookup)." entries found.");
}

1;	# Do not remove this line
