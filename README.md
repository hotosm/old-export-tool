# HOT Export server

Accepts a JOSM preset for describing custom tags and a custom bounding box.

Outputs jobs and tags found. Jobs can be re-run.

Formats include:

 * pbf
 * SQLite / Spatialite
 * PostGIS sql dump
 * Zipped shapefiles
 
Written by the awesome folks at https://github.com/geofabrik

##Setup and Modifications

*This section was taken from the custom-extracts.pdf file found in the docu folder with additional comments italicized. Please note that the repository may still have many missing assets (Ruby on Rails name for
static files).* 

Information in this chapter pertains to future installations on different servers; on hot-export.geofabrik.de, these steps are already in place.

###4.1 Prerequisites

The system requires the following external components:

* Apache web server with mod_passenger (or other suitable server)
* Rails, Ruby, and gems as per bundle
* Postgres database
* zip (for creating zipped shape files)
* Perl with libdbd-xbase-perl module
* gdal utility
* protobuf library
* Java runtime

###4.2 Directory Setup

The shell/perl scripts assume that things are installed in /home/hot.

*The rest of the directory is set up in the following ways:* 

/home/hot/etc/plygons – .poly files for each area (currently Haiti only)

/home/hot/bin – scripts and custom_data_export binary

/home/hot/osmosis – Osmosis installation

/home/hot/var/extracts – place for raw OSM data (currently only haiti.osm.pbf)

/home/hot/var/osmosis-status-dir – place for Osmosis replication status 

/home/hot/var/diffs, /home/hot/var/runs, /home/hot/log – writable empty directories 

/home/hot/web – Rails application

###4.3 Database and Web Server Setup

The system expects to have a database user named hot_export (password hot_export) who is allowed to create database. Then, the database can be created with rake db::create (for production mode) and db::migrate after that.

The web server needs to be pointed to the appropriate root directory for the application, and an Alias needs to be created so that users can download the files created by the backend:

```
<VirtualHost *:80>
  ServerAdmin webmaster@localhost 
     DocumentRoot /home/hot/web/public 
      <Directory /> 
              Options Indexes FollowSymLinks
              AllowOverride None
       </Directory>
       Alias /download /home/hot/var/runs
       ErrorLog /var/log/apache2/error.log
       LogLevel warn
       CustomLog /var/log/apache2/access.log combined
  </VirtualHost>
```

###4.4 OSM Updater and Request Processor Setup

The OSM updater must be primed with an initial data extract for each region, and matching Osmosis replication settings. This can be done by cutting out the desired polygon out of a full planet file or Geofabrik extract, and then initializing the Osmosis replication directory with --rrii and setting the state.txt file with the help of http://toolserver.org/~mazder/replicate-sequences/.

For both the updater and the request processor, a cron job needs to be created so that they are restarted if they should die or the machine should be rebooted:

```
  # m h  dom mon dow   command <br />
  * * * * * /home/hot/bin/check_export.sh <br />
  * * * * * /home/hot/bin/check_update.sh
```

It is suggested to run the backend application under the user “hot”. Make sure that the directory /home/hot/var/runs is readable by www-data though, so that downloads are possible.

###4.5 Adding File Formats

Adding new output file formats is relatively straightforward in the request processor. Say you wanted to add a basic KML output; simply edit export_request_processor.pl and find the lines that say

```
	# call ogr2ogr to make Spatiallite file
    mysystem("ogr2ogr -overwrite -f 'SQLite' -dsco SPATIALLITE=YES $OUTPUT_PATH/
$rid/extract.spatiallite $OUTPUT_PATH/$rid/extract.sqlite");      
addfile($rid, "extract.spatiallite", "Spatiallite file");
```

The “mysystem” line runs an Unix utility, and the “addfile” line makes sure the resulting file is probed for its size and added to the output table in the database so that the user gets a download link for that later.

To add KML processing, add a block like this:

```    
    # call ogr2ogr to make KML file
    mysystem("ogr2ogr -overwrite -f 'KML' -$OUTPUT_PATH/$rid/extract.kml $OUTPUT_PATH/$rid/extract.sqlite");
       addfile($rid, "extract.kml“, "KML File");
```

That's all.

###4.6 Adding New Regions, or Changing Existing Regions

Instead of keeping a continuously updated database for the whole world, this tool keeps individual data files for each region of interest. Each region must have:

* an extract polygon in /home/hot/etc/polygons (regionname.poly)
* a current extract in /home/hot/var/extracts (regionname.osm.pbf)
* an entry in the “regions” table in the database, comprising internal name (used for file names), external name (used to display in the web interface), and a bounding polygon
* a polygon geometry contained in the KML files used for display and validation in the web interface, located in /home/hot/web/public/kml/

To add a new region into the running system, or to modify an existing region, the following steps are recommended:

1. stop the application (shut down Apache server)
2. install new polygon to /home/hot/etc/polygons
3. disable the update loop (disable cronjob and kill update-loop.sh)
4. install the current extract for the new region (see below)
5. go to the polygons directory and run the “makekml” perl script:
       perl /home/hot/git-checkout/util/makekml.pl > sql.txt

	This will generate the KML files that you have to move to /home/hot/web/public/kml/, and it will also generate a couple of SQL insert/update statements. Do not run these statements verbatim; only cut and paste from sql.txt the statement that inserts your new region (or updates the region you have changed) – be sure to check the region_id against your existing “regions” database table and fix if necessary.

6. manually insert a record into the regions table for the new region; you can use the poly2bb.pl utility to compute the bbox of the polygon you have installed. 

	Example:
>       insert into regions values(0,'haiti','Haiti',-74.825290,17.382750,-
>       68.161740,20.460020,now(),now());

7. enable cronjobs, restart Apache

To efficiently update all local extracts, the server will only pull updates from the OSM server once and then apply them to all extracts. This means that all extracts share a common Osmosis “state.txt” file (located in /home/hot/var/osmosis-status-dir). If you install a new extract, it must not be older than the “state.txt” file describes, or else you run the risk of losing the latest edits to that area. If you cannot procure a current extract for setup, then you can install an older extract and set the state.txt file accordingly. This will lead to some updates being applied to the already existing extracts a second time, but Osmosis will detect that and handle it correctly.


## License

This code is licensed under the revised BSD license a.k.a 2-clause BSD license or FreeBSD license. The standard license boilerplate text follows below.

This repository contains required parts of the OpenLayers and JQuery Javascript libaries. OpenLayers uses the same BSD license as this code. JQuery is licensed under the MIT license or the GNU GPL v2 (your choice).

Copyright (c) 2012 Geofabrik GmbH All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.