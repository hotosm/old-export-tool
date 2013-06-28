#!/usr/bin/perl

use strict;

my @rings;

print <<EOF;
CREATE TABLE regions (
    id integer NOT NULL,
    internal_name character varying(255),
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    polygon geometry(Polygon,4326)
);
EOF

my $counter = 0;

foreach my $poly(glob "*.poly")
{

    my $kml = "";
    my $wkt = "";
    $counter++;

    $poly =~ /(.*)\.poly/;
    my $region = $1;

    open(P, $poly);
    while(<P>)
    {
        if (/^\s+([-0123456789Ee+.]+)\s+([-0123456789Ee+.]+)/)
        {
            $wkt .= "," if ($wkt ne "");
            $kml .= " " if ($kml ne "");
            $wkt .= sprintf("%f %f", $1, $2);
            $kml .= sprintf("%f,%f", $1, $2);
        }
    }
    close P;

    printf "\n\n";
    printf("insert into regions (id,internal_name,name,created_at,updated_at,polygon) values($counter, '$region','$region',now(),now(),st_setsrid(st_geomfromtext('POLYGON(($wkt))'),4326));\n");
    printf("update regions set polygon = setsrid(st_geomfromtext('POLYGON(($wkt))'),4326) where internal_name='$region';\n");

    push(@rings, $kml);
}

open(KML, "> check.kml") or die;
print KML <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.0">
<Document>
  <Placemark>
    <MultiGeometry>
EOF

foreach my $ring(@rings)
{
    print KML "      <Polygon><outerBoundaryIs><LinearRing><coordinates>";
    print KML $ring;
    print KML "</coordinates></LinearRing></outerBoundaryIs></Polygon>\n";
}

print KML <<EOF;
    </MultiGeometry>
  </Placemark> 
</Document> 
</kml>
EOF

close KML;

open(KML, "> loch.kml") or die;
print KML <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.0">
<Document>
  <Placemark>
    <Polygon>
      <outerBoundaryIs><LinearRing><coordinates>180,85 -180,85 -180,-85 180,-85 180,85</coordinates></LinearRing></outerBoundaryIs>
EOF

foreach my $ring(@rings)
{
    print KML "      <innerBoundaryIs><LinearRing><coordinates>";
    print KML $ring;
    print KML "</coordinates></LinearRing></innerBoundaryIs>\n";
}

print KML <<EOF;
    </Polygon>
  </Placemark> 
</Document> 
</kml>
EOF

close KML;
