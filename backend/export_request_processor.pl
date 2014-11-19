#!/usr/bin/perl

use strict;
use DBI;
use XBase;

my $DBNAME='hot_export_production';
my $DBUSER='hot_export';
my $DBPASS='hot_export';
my $DBHOST='localhost';

my $logfile;

chdir "/home/hot";

my $EXTRACT_PATH="var/extracts";
my $OUTPUT_PATH="var/runs";
my $UPLOAD_PATH="web/public/uploads";
my $CDE="bin/cde";
my $OSMOSIS="osmosis/bin/osmosis";

my $dbh = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", $DBUSER, $DBPASS, {});

my $sth_fetch = $dbh->prepare("SELECT runs.id as id, jobs.name as name, regions.internal_name as region, job_id, latmin,latmax,lonmin,lonmax FROM runs,jobs,regions WHERE state='new' and runs.job_id=jobs.id AND jobs.region_id = regions.id LIMIT 1");
my $sth_fetch_tags = $dbh->prepare("SELECT * FROM tags WHERE job_id=?");
my $sth_fetch_transforms = $dbh->prepare("SELECT filename FROM uploads u,jobs_uploads ju where u.uptype='tagtransform' and u.visibility and u.id=ju.upload_id and ju.job_id=?");
my $sth_fetch_translations = $dbh->prepare("SELECT filename FROM uploads u,jobs_uploads ju where u.uptype='translation' and u.visibility and u.id=ju.upload_id and ju.job_id=?");
my $sth_update_running = $dbh->prepare("UPDATE runs SET state='running',updated_at=now() at time zone 'utc' WHERE id=?");
my $sth_update_finish = $dbh->prepare("UPDATE runs SET state='success',updated_at=now() at time zone 'utc' WHERE id=?");
my $sth_update_error = $dbh->prepare("UPDATE runs SET state='error',updated_at=now() at time zone 'utc', comment=? WHERE id=?");
my $sth_add_download = $dbh->prepare("INSERT INTO downloads (run_id, url, name, size, created_at, updated_at) VALUES(?, ?, ?, ?, now() at time zone 'utc', now() at time zone 'utc')");

$sth_fetch->execute();

if (my $run = $sth_fetch->fetchrow_hashref)
{
    my $rid = sprintf("%06d", $run->{'id'});
    my $jid = $run->{'job_id'};
    my $extname = $run->{'region'};
    my $name = lc($run->{'name'});

    # clean name so it becomes usable as a file name
    $name =~ s/\W/_/g;
    $name =~ s/_+/_/g;
    $name = $1 if ($name =~ /^_?(.*?)_?$/);

    printf(STDERR "job $jid, rid $rid, output file name $name\n");
    $logfile = "$OUTPUT_PATH/$rid/log.txt";
    $sth_update_running->execute($run->{id});
    

    $sth_fetch_tags->execute($jid);
    my @pointtags;
    my @areatags;
    my @linetags;

    while(my $tag = $sth_fetch_tags->fetchrow_hashref)
    { 
        if ($tag->{'geometrytype'} eq "point")
        {
            push(@pointtags, $tag->{'key'});
        }
        elsif ($tag->{'geometrytype'} eq "line")
        {
            push(@linetags, $tag->{'key'});
        }
        elsif ($tag->{'geometrytype'} eq "polygon")
        {
            push(@areatags, $tag->{'key'});
        }
    }

    mkdir "$OUTPUT_PATH/$rid";

    my $osmosis = sprintf("$OSMOSIS --read-pbf $EXTRACT_PATH/$extname.osm.pbf --bb left=%f right=%f top=%f bottom=%f clipIncompleteEntities=true --write-pbf $OUTPUT_PATH/$rid/rawdata.osm.pbf", 
        $run->{lonmin}, $run->{lonmax}, $run->{latmax}, $run->{latmin});

    if (!mysystem($osmosis))
    {
        $sth_update_error->execute("error in osm2pgsql", $rid);
        exit 1;
    }

    addfile($rid, "rawdata.osm.pbf", "OSM source file (.pbf)");

    $ENV{"CDE_FIELDS_NODES"} = join(",", @pointtags);
    $ENV{"CDE_FIELDS_WAYS"} = join(",", @linetags);
    $ENV{"CDE_FIELDS_AREAS"} = join(",", @areatags);

    mymsg("CDE_FIELDS_NODES=".$ENV{"CDE_FIELDS_NODES"}."\n");
    mymsg("CDE_FIELDS_WAYS=".$ENV{"CDE_FIELDS_WAYS"}."\n");
    mymsg("CDE_FIELDS_AREAS=".$ENV{"CDE_FIELDS_AREAS"}."\n");

    $sth_fetch_translations->execute($jid);
    my @transtables;
    while(my $tt = $sth_fetch_translations->fetchrow_hashref)
    {
       push(@transtables, $UPLOAD_PATH."/".$tt->{filename});
    }
    $ENV{"CDE_TRANSLATION_TABLES"} = join(",", @transtables);
    mymsg("CDE_TRANSLATION_TABLES=".$ENV{"CDE_TRANSLATION_TABLES"}."\n");
    
    if (!mysystem("$CDE $OUTPUT_PATH/$rid/rawdata.osm.pbf $OUTPUT_PATH/$rid/$name.sqlite"))
    {
        $sth_update_error->execute("error in CDE", $rid);
        exit 1;
    }
    mymsg("cde finished.\n");

    # CDE program creates the SQLite file.
    addfile($rid, "$name.sqlite", "SQLite file");

    $sth_fetch_transforms->execute($jid);
    while(my $tfm = $sth_fetch_transforms->fetchrow_hashref)
    {
        mymsg("running transformation: ".$tfm->{filename}."\n");
        mysystem("spatialite $OUTPUT_PATH/$rid/$name.sqlite < $UPLOAD_PATH/".$tfm->{filename});
    }

    # call ogr2ogr to make PostGIS dump 
    mysystem("ogr2ogr -overwrite -f 'PGDump' -dsco PG_USE_COPY=YES -dsco GEOMETRY_NAME=way $OUTPUT_PATH/$rid/$name.sql $OUTPUT_PATH/$rid/$name.sqlite");
    mysystem("gzip $OUTPUT_PATH/$rid/$name.sql");
    addfile($rid, "$name.sql.gz", "PostGIS dump file (compressed - .sql.gz)");

    # call ogr2ogr to make Spatiallite file
    mysystem("ogr2ogr -overwrite -f 'SQLite' -dsco SPATIALLITE=YES $OUTPUT_PATH/$rid/$name.spatiallite $OUTPUT_PATH/$rid/$name.sqlite");
    addfile($rid, "$name.spatiallite", "Spatiallite file");

    # call ogr2ogr to make shape files in temporary directory
    mkdir "/tmp/$rid-shp";
    mysystem("ogr2ogr -overwrite -f 'ESRI Shapefile' /tmp/$rid-shp $OUTPUT_PATH/$rid/$name.sqlite -lco ENCODING=UTF-8");

    # load ogr2ogr output to find out field name truncations
    my $crosswalk = {};
    open(RL, $logfile);
    while(<RL>)
    {
        if (/Warning 6: Normalized\/laundered field name: '(.*)' to '(.*)'/)
        {
            $crosswalk->{lc($2)} = lc($1);
        }
    }
    close(RL);

    # prepare crosswalk file for each dbf 
    foreach my $shp(glob("/tmp/$rid-shp/*.dbf"))
    {
        my $cw = $shp;
        $cw =~ s/dbf$/crosswalk.csv/;
        open(CW, ">$cw");
        my $dbf = new XBase($shp);
        my $x = 1;
        foreach my $field($dbf->field_names)
        {
            $field = lc($field);
            printf CW "%d,\"%s\",\"%s\"\n", $x, $crosswalk->{$field} || $field, $field;
            $x++;
        }
        close(CW);
    }

    # overwrite PRJs and create CPG
    foreach my $prj(glob("/tmp/$rid-shp/*.prj"))
    {
        open(PRJ, ">$prj");
        print PRJ 'PROJCS["WGS 84 / Pseudo-Mercator",GEOGCS["Popular Visualisation CRS",DATUM["Popular_Visualisation_Datum",SPHEROID["Popular Visualisation Sphere",6378137,0,AUTHORITY["EPSG","7059"]],TOWGS84[0,0,0,0,0,0,0],AUTHORITY["EPSG","6055"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.01745329251994328,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4055"]],UNIT["metre",1,AUTHORITY["EPSG","9001"]],PROJECTION["Mercator_1SP"],PARAMETER["central_meridian",0],PARAMETER["scale_factor",1],PARAMETER["false_easting",0],PARAMETER["false_northing",0],AUTHORITY["EPSG","3785"],AXIS["X",EAST],AXIS["Y",NORTH]]';
        close(PRJ);
        $prj =~ /(.*)\.prj$/;
        my $cpg = $1.'.cpg';
        open(CPG, ">$cpg");
        print(CPG "UTF-8\n");
        close(CPG);
    }

    # zip resulting shapefile components and remove tempdir
    mysystem("zip -j $OUTPUT_PATH/$rid/$name.shp.zip /tmp/$rid-shp/*");
    addfile($rid, "$name.shp.zip", "ESRI Shapefile (zipped)");
    mysystem("rm -rf /tmp/$rid-shp");

    # make KMZ file
    mkdir ("$OUTPUT_PATH/tmp/$rid-kml");
    mysystem("ogr2ogr -f 'KML' $OUTPUT_PATH/tmp/$rid-kml/doc.kml $OUTPUT_PATH/$rid/$name.sqlite");
    mysystem("zip -j $OUTPUT_PATH/$rid/$name.kmz $OUTPUT_PATH/tmp/$rid-kml/*");
    mysystem("rm -rf $OUTPUT_PATH/tmp/$rid-kml");
    addfile($rid, "$name.kmz", "Google Earth (KMZ) file");

    # ADD FURTHER ogr2ogr CALLS HERE!
    mkdir ("$OUTPUT_PATH//tmp/$rid-gmapsupp");
    mysystem("java -Xmx3096m -jar /home/hot/mkgmap/mkgmap.jar --keep-going --route --index -n 80000111 --description='$name' --gmapsupp --draw-priority=99 --family-id=3456 --nsis --series-name='$name' --output-dir=$OUTPUT_PATH/tmp/$rid-gmapsupp $OUTPUT_PATH/$rid/rawdata.osm.pbf");
    mysystem("gzip < $OUTPUT_PATH/tmp/$rid-gmapsupp/gmapsupp.img > $OUTPUT_PATH/$rid/gmapsupp.img.gz", 1);
    mysystem("rm -rf $OUTPUT_PATH//tmp/$rid-gmapsupp");
    addfile($rid, "gmapsupp.img.gz", "Garmin map (EXPERIMENTAL; compressed)");

    # finally record log file
    addfile($rid, "log.txt", "job log file (log.txt)");

    $sth_update_finish->execute($rid);
}
else
{
    printf(STDERR "no job waiting\n");    
};

sub mymsg
{
    my $msg = shift;
    open (L, ">> $logfile");
    print(L $msg);
    close(L);
}

sub mysystem 
{
    my $call = shift;
    my $nolog = shift;

    mymsg("$call\n");
    if (defined($nolog) && $nolog) 
    {
        system ("$call 2>>$logfile");
    }
    else
    {
        system ("$call >> $logfile 2>&1");
    }

    if ($? == -1) {
        mymsg("failed to execute: $!");
        return 0;
    }
    elsif ($? & 127) {
        mymsg(sprintf "child died with signal %d, %s coredump",
               ($? & 127),  ($? & 128) ? 'with' : 'without');
	return 0;
    }
    elsif ($? >> 8) {
        mymsg(sprintf "child exited with value %d\n", $? >> 8);
        return 0;
    }
    return 1;
}

sub addfile
{
    my ($rid, $fn, $des) = @_;
    my $local = "$OUTPUT_PATH/$rid/$fn";
    my $remote = "/download/$rid/$fn";
    my $size_raw = -s $local;
    my $suffixes = [ "B", "KB", "MB", "GB", "TB", "PB" ];
    my $spec = 0;
    while($size_raw > 1000)
    {
        $size_raw = ($size_raw+512)/1024;
        $spec++;
    }
    my $size = sprintf("%.1f%s", $size_raw, $suffixes->[$spec]);
    $sth_add_download->execute($rid, $remote, $des, $size);
}
