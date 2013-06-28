#include <map>
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <boost/algorithm/string.hpp>
#include <boost/regex.hpp>

#define OSMIUM_WITH_PBF_INPUT

#include <ogr_api.h>
#include <ogrsf_frmts.h>

#include <osmium.hpp>
#include <osmium/storage/byid/sparse_table.hpp>
#include <osmium/storage/byid/mmap_file.hpp>

#include <osmium/handler/coordinates_for_ways.hpp>
#include <osmium/geometry/multipolygon.hpp>
#include <osmium/geometry/ogr.hpp>
#include <osmium/geometry/ogr_multipolygon.hpp>
#include <osmium/multipolygon/assembler.hpp>


typedef Osmium::Storage::ById::SparseTable<Osmium::OSM::Position> storage_sparsetable_t;
typedef Osmium::Storage::ById::MmapFile<Osmium::OSM::Position> storage_mmap_t;
typedef Osmium::Handler::CoordinatesForWays<storage_sparsetable_t, storage_mmap_t> cfw_handler_t;
typedef std::vector<std::string> stringv;
typedef std::map<std::string, std::string> stringm;
typedef std::map<std::string, stringm> transmap;

// ------------------------------------------------------------------------------

class CDEHandlerPass2 : public Osmium::Handler::Base {

    const stringv m_fields_nodes;
    const stringv m_fields_ways;
    const stringv m_fields_areas;
    const transmap m_translations;

    OGRDataSource* m_data_source;
    OGRSpatialReference m_srs_wgs84;
    OGRSpatialReference m_srs_out;
    OGRCoordinateTransformation *m_transformation;

    OGRLayer* m_layer_point;
    OGRLayer* m_layer_line;
    OGRLayer* m_layer_polygon;
    OGRLayer* m_layer_roads;

    std::map<const std::string, int> m_highway2z;
    char longint[100];

public:

    CDEHandlerPass2(const std::string& outfile,
                    const stringv& fields_nodes, const stringv& fields_ways, stringv fields_areas, const transmap& tm) :
        m_fields_nodes(fields_nodes),
        m_fields_ways(fields_ways),
        m_fields_areas(fields_areas),
        m_translations(tm),
        m_srs_wgs84(),
        m_srs_out()
    {
        if (m_srs_wgs84.SetWellKnownGeogCS("WGS84") != OGRERR_NONE) 
        {
            std::cerr << "Can't initalize WGS84 SRS\n";
            exit(1);
        }

        if (m_srs_out.importFromEPSG(3857) != OGRERR_NONE) 
        {
            // if configuration for EPSG:3857 is not found, fall back to hard-coded one
            if (m_srs_out.importFromProj4("+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs <>") != OGRERR_NONE) 
            {
                std::cerr << "Can't initialize output SRS\n";
                exit(1);
            }
        }

        m_transformation = OGRCreateCoordinateTransformation(&m_srs_wgs84, &m_srs_out);
        if (!m_transformation) {
            std::cerr << "Can't create coordinate transformation\n";
            exit(1);
        }

        init_ogr(outfile);

        m_highway2z["minor"] = 3;
        m_highway2z["road"] = 3;
        m_highway2z["unclassified"] = 3;
        m_highway2z["residential"] = 3;
        m_highway2z["tertiary_link"] = 4;
        m_highway2z["tertiary"] = 4;
        m_highway2z["secondary_link"] = 6;
        m_highway2z["secondary"] = 6;
        m_highway2z["primary_link"] = 7;
        m_highway2z["primary"] = 7;
        m_highway2z["trunk_link"] = 8;
        m_highway2z["trunk"] = 8;
        m_highway2z["motorway_link"] = 9;
        m_highway2z["motorway"] = 9;
    }

    ~CDEHandlerPass2() {
        OGRDataSource::DestroyDataSource(m_data_source);
        OCTDestroyCoordinateTransformation(m_transformation);
        OGRCleanupAll();
    }

    void node(const shared_ptr<Osmium::OSM::Node const>& node) 
    {
        OGRFeature* feature = 0;
        stringv::const_iterator it;
        for (it=m_fields_nodes.begin(); it != m_fields_nodes.end(); ++it) 
        {
            const char* value = node->tags().get_value_by_key(it->c_str());
            if (value) 
            {
                if (!feature) 
                {
                    feature = create_point_feature(node.get());
                }
                translateAndSetField(feature, it->c_str(), value);
            }
        }

        if (feature) 
        {
            if (m_layer_point->CreateFeature(feature) != OGRERR_NONE) {
                std::cerr << "Failed to create feature (node.id=" << node->id() << ").\n";
                exit(1);
            }
            OGRFeature::DestroyFeature(feature);
        }
    }

    void way(const shared_ptr<const Osmium::OSM::Way>& way) 
    {
        OGRFeature* feature = 0;
        stringv::const_iterator it;
        for (it=m_fields_ways.begin(); it != m_fields_ways.end(); ++it) 
        {
            const char* value = way->tags().get_value_by_key(it->c_str());
            if (value) {
                if (!feature) 
                {
                    feature = create_line_feature(way.get(), m_layer_line);
                }
                translateAndSetField(feature, it->c_str(), value);
            }
        }
        if (feature) 
        {
            if (m_layer_line->CreateFeature(feature) != OGRERR_NONE) 
            {
                std::cerr << "Failed to create feature (way.id=" << way->id() << ").\n";
                exit(1);
            }
            OGRFeature::DestroyFeature(feature);
        }

        const char* railway  = way->tags().get_value_by_key("railway");
        const char* highway  = way->tags().get_value_by_key("highway");
        const char* boundary = way->tags().get_value_by_key("boundary");

        if (highway && 
                strcmp(highway, "motorway_link") &&
                strcmp(highway, "motorway") &&
                strcmp(highway, "trunk_link") &&
                strcmp(highway, "trunk") &&
                strcmp(highway, "primary_link") &&
                strcmp(highway, "primary") &&
                strcmp(highway, "secondary_link") &&
                strcmp(highway, "secondary")) {
            highway = 0;
        }

        if (boundary && strcmp(boundary, "administrative")) 
        {
            boundary = 0;
        }

        if (railway || highway || boundary) 
        {
            feature = create_line_feature(way.get(), m_layer_roads);
            translateAndSetField(feature, "railway", railway);
            translateAndSetField(feature, "highway", highway);
            translateAndSetField(feature, "boundary", boundary);
            if (m_layer_roads->CreateFeature(feature) != OGRERR_NONE) 
            {
                std::cerr << "Failed to create feature (way.id=" << way->id() << ").\n";
                exit(1);
            }
            OGRFeature::DestroyFeature(feature);
        }
    }

    void area(const shared_ptr<Osmium::OSM::Area const>& area)
    {
        OGRFeature* feature = 0;
        stringv::const_iterator it;
        for (it=m_fields_areas.begin(); it != m_fields_areas.end(); ++it) 
        {
            const char* value = area->tags().get_value_by_key(it->c_str());
            if (value) 
            {
                if (!feature) 
                {
                    try  
                    {
                        feature = create_area_feature(area);
                    } 
                    catch (Osmium::Geometry::IllegalGeometry) 
                    {
                        std::cerr << "Ignoring illegal geometry for multipolygon " << area->id() << ".\n";
                        return;
                    }
                }
                translateAndSetField(feature, it->c_str(), value);
            }
        }
        if (feature) 
        {
            if (m_layer_polygon->CreateFeature(feature) != OGRERR_NONE) 
            {
                std::cerr << "Failed to create feature (area.id=" << area->id() << ").\n";
                exit(1);
            }
            OGRFeature::DestroyFeature(feature);
        }
    }

private:

    void translateAndSetField(OGRFeature* feature, const char *key, const char *value)
    {
        if ((key) && (value))
        {
            transmap::const_iterator a = m_translations.find(key);
            if (a != m_translations.end())
            {
                stringm::const_iterator b = a->second.find(value);
                if (b != a->second.end())
                {
                    feature->SetField(key, b->second.c_str());
                    return;
                }
            }
            a = m_translations.find("");
            if (a != m_translations.end())
            {
                stringm::const_iterator b = a->second.find(value);
                if (b != a->second.end())
                {
                    feature->SetField(key, b->second.c_str());
                    return;
                }
            }
        }
        feature->SetField(key, value);
    }

    OGRLayer* init_layer(const std::string& name, const stringv& fields, const OGRwkbGeometryType type) {
        std::cerr << "Creating layer: " << name << "\n";

        OGRLayer* layer = m_data_source->CreateLayer(name.c_str(), &m_srs_out, type, NULL);
        if (layer == NULL) {
            std::cerr << "Layer creation failed (" << name << ").\n";
            exit(1);
        }

        std::cerr << "  Creating field: osm_id\n";
        OGRFieldDefn field_osm_id("osm_id", OFTString);
        field_osm_id.SetWidth(11);
        if (layer->CreateField(&field_osm_id) != OGRERR_NONE ) {
            std::cerr << "Creating field 'osm_id' failed.\n";
            exit(1);
        }

        std::cerr << "  Creating field: z_order\n";
        OGRFieldDefn field_z_order("z_order", OFTInteger);
        field_z_order.SetWidth(4);
        if (layer->CreateField(&field_z_order) != OGRERR_NONE ) {
            std::cerr << "Creating field 'z_order' failed.\n";
            exit(1);
        }

        std::cerr << "  Creating field: way_area\n";
        OGRFieldDefn field_way_area("way_area", OFTReal);
        field_way_area.SetWidth(10);
        if (layer->CreateField(&field_way_area) != OGRERR_NONE ) {
            std::cerr << "Creating field 'way_area' failed.\n";
            exit(1);
        }

        stringv::const_iterator it;
        for (it = fields.begin(); it != fields.end(); ++it) {
            std::cerr << "  Creating field: " << *it << "\n";
            OGRFieldDefn field_tag((*it).c_str(), OFTString);
            field_tag.SetWidth(255);
            if (layer->CreateField(&field_tag) != OGRERR_NONE ) {
                std::cerr << "Creating field '" << *it << "' failed.\n";
                exit(1);
            }
        }

        return layer;
    }

    void init_ogr(const std::string& outfile) {
        OGRRegisterAll();

        const char* driver_name = "SQLite";
        OGRSFDriver* driver = OGRSFDriverRegistrar::GetRegistrar()->GetDriverByName(driver_name);
        if (driver == NULL) {
            std::cerr << driver_name << " driver not available.\n";
            exit(1);
        }

        CPLSetConfigOption("OGR_SQLITE_SYNCHRONOUS", "FALSE");
        const char* options[] = { "SPATIALITE=TRUE", NULL };

        m_data_source = driver->CreateDataSource(outfile.c_str(), const_cast<char**>(options));
        if (m_data_source == NULL) {
            std::cerr << "Creation of output file failed.\n";
            exit(1);
        }

        m_layer_point   = init_layer("planet_osm_point",   m_fields_nodes, wkbPoint);
        m_layer_line    = init_layer("planet_osm_line",    m_fields_ways,  wkbLineString);
        m_layer_polygon = init_layer("planet_osm_polygon", m_fields_areas, wkbMultiPolygon);

        stringv fields_roads;
        fields_roads.push_back("railway");
        fields_roads.push_back("highway");
        fields_roads.push_back("boundary");
        m_layer_roads = init_layer("planet_osm_roads", fields_roads, wkbLineString);
    }

    int calculate_z_order(const Osmium::OSM::Object* object) {
        int z = 0;

        const Osmium::OSM::TagList& tags = object->tags();

        if (const char* highway = tags.get_value_by_key("highway")) {
            z += m_highway2z[highway];
        }
        if (tags.get_value_by_key("railway")) {
            z += 5;
        }
        if (const char* layer = tags.get_value_by_key("layer")) {
            int l = atoi(layer);
            z += 10 * l;
        }
        if (const char *bridge = tags.get_value_by_key("bridge")) {
            if (!strcmp(bridge, "yes") ||
                !strcmp(bridge, "true") ||
                !strcmp(bridge, "1")) {
                z += 10;
            }
        }
        if (const char *tunnel = tags.get_value_by_key("tunnel")) {
            if (!strcmp(tunnel, "yes") ||
                !strcmp(tunnel, "true") ||
                !strcmp(tunnel, "1")) {
                z -= 10;
            }
        }

        return z;
    }

    OGRFeature* create_point_feature(const Osmium::OSM::Node* node) {
        OGRFeature* feature = OGRFeature::CreateFeature(m_layer_point->GetLayerDefn());
        Osmium::Geometry::Point point(*node);
        OGRPoint* ogrgeom = Osmium::Geometry::create_ogr_geometry(point);
        ogrgeom->transform(m_transformation);
        feature->SetGeometryDirectly(ogrgeom);
        sprintf(longint, "%ld", node->id());
        feature->SetField("osm_id", longint);
        feature->SetField("z_order", calculate_z_order(node));
        feature->SetField("way_area", 0);
        return feature;
    }

    OGRFeature* create_line_feature(const Osmium::OSM::Way* way, OGRLayer* layer) {
        OGRFeature* feature = OGRFeature::CreateFeature(layer->GetLayerDefn());
        Osmium::Geometry::LineString linestring(*way);
        OGRLineString* ogrgeom = Osmium::Geometry::create_ogr_geometry(linestring);
        ogrgeom->transform(m_transformation);
        feature->SetGeometryDirectly(ogrgeom);
        sprintf(longint, "%ld", way->id());
        feature->SetField("osm_id", longint);
        feature->SetField("z_order", calculate_z_order(way));
        feature->SetField("way_area", 0);
        return feature;
    }

    OGRFeature* create_area_feature(const shared_ptr<Osmium::OSM::Area const>& area)
    {
        OGRFeature* feature = OGRFeature::CreateFeature(m_layer_polygon->GetLayerDefn());
        Osmium::Geometry::MultiPolygon mp(*area);
        OGRMultiPolygon* ogrgeom = Osmium::Geometry::create_ogr_geometry(mp);
        ogrgeom->transform(m_transformation);
        feature->SetGeometryDirectly(ogrgeom);
        sprintf(longint, "%ld", area->id());
        feature->SetField("osm_id", longint);
        feature->SetField("z_order", calculate_z_order(area.get()));
        feature->SetField("way_area", ogrgeom->get_Area());
        return feature;
    }

};

// ------------------------------------------------------------------------------

int main(int argc, char *argv[]) {

    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " OSMFILE OUTFILE\n";
        exit(1);
    }

    std::string outfile(argv[2]);

    stringv fields_nodes;
    stringv fields_ways;
    stringv fields_areas;
    stringv translation_tables;

    if (const char* str = getenv("CDE_FIELDS_NODES")) 
    {
        boost::split(fields_nodes, str, boost::is_any_of(","));
    }
    if (const char* str = getenv("CDE_FIELDS_WAYS")) 
    {
        boost::split(fields_ways, str,  boost::is_any_of(","));
    }
    if (const char* str = getenv("CDE_FIELDS_AREAS")) 
    {
        boost::split(fields_areas, str, boost::is_any_of(","));
    }
    if (const char* str = getenv("CDE_TRANSLATION_TABLES")) 
    {
        boost::split(translation_tables, str, boost::is_any_of(","));
    }

    if (fields_nodes.empty() || fields_ways.empty() || fields_areas.empty()) 
    {
        std::cerr << "You need to set the env variables CDE_FIELDS_NODES, CDE_FIELDS_WAYS, and CDE_FIELDS_AREAS before calling this program!\n";
        exit(1);
    }

    transmap tm;

    BOOST_FOREACH(std::string tt, translation_tables)
    {
        std::string line;
        std::ifstream file(tt.c_str());
        boost::regex translation_regex("^((\\S+)=)?(\\S+)\\s+(.*?)\\s*$", boost::regex::perl);
        boost::regex empty_regex("^\\S*(#.*)?$", boost::regex::perl);
        boost::cmatch matches;

        if (file.is_open())
        {
            std::cerr << "loading translations from " << tt << "..." << std::endl;
            int count = 0;
            int lineno = 0;
            while(file.good())
            {
                lineno++;
                getline(file, line);
                if (boost::regex_match(line.c_str(), empty_regex))
                {
                    // ignore
                }
                else if (boost::regex_match(line.c_str(), matches, translation_regex))
                {
                    std::string key(matches[2].first, matches[2].second);
                    std::string oldval(matches[3].first, matches[3].second);
                    std::string newval(matches[4].first, matches[4].second);
                    tm[key][oldval] = newval;
                    count++;
                }
                else
                {
                    std::cerr << "line " << lineno << " cannot be parsed: " << line << std::endl;
                }
            }
            file.close();
            std::cerr << count << " translations loaded from " << tt << std::endl;
        }
        else
        {
            std::cerr << "cannot open translation file '" << tt << "', continuing without" << std::endl;
        }
    }

    Osmium::OSMFile infile(argv[1]);

    CDEHandlerPass2 handler_pass2(outfile, fields_nodes, fields_ways, fields_areas, tm);

    bool attempt_repair = true;
    typedef Osmium::MultiPolygon::Assembler<CDEHandlerPass2> assembler_t;
    assembler_t assembler(handler_pass2, attempt_repair);
    storage_sparsetable_t store_pos;
    storage_mmap_t store_neg;

    cfw_handler_t cfw_handler(store_pos, store_neg);
    typedef Osmium::Handler::Sequence<cfw_handler_t, assembler_t::HandlerPass2> sequence_handler_t;
    sequence_handler_t sequence_handler(cfw_handler, assembler.handler_pass2());

    // first pass
    std::cerr << "Doing 1st pass...\n";
    Osmium::Input::read(infile, assembler.handler_pass1());
    std::cerr << "1st pass finished.\n";

    // second pass
    std::cerr << "Doing 2nd pass...\n";
    Osmium::Input::read(infile, sequence_handler);
    std::cerr << "2nd pass finished.\n";
}

