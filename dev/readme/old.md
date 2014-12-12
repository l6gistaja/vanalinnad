### Adding new historical map to site

1. Cut away and whiten original maps edges, legends, empty areas etc. It makes tile generation speed, repo size and download speed smaller.
1. [Georeference](https://github.com/l6gistaja/vanalinnad/blob/master/vector/places/Tallinn/gdal1968.txt) source map image: ```gdal_translate {SOURCE_IMAGE_FILE}  {GEOREFERENCED_PNG_FILE} -of PNG ``` ```-gcp {X_COORDINATE_OF_GCP_ON_SOURCE_IMAGE} {Y_COORDINATE_OF_GCP_ON_SOURCE_IMAGE}``` ```{EAST_COORDINATE_OF_GCP} {NORTH_COORDINATE_OF_GCP}```. Choose and specify image (in pixels) and geographical coordinates of at least 3 G(round)C(ontrol)P(oint)s. For example, GCPs can be narrow crossroads which are on both historic and modern maps. You can use [dev/coords.html](dev/coords.html) for finding GCPs geographical coordinates. Append ```gdal_translate ...``` to the end of ```{VANALINNAD_ROOT_DIR}/vector/places/{PLACE}/gdal{YEAR}.txt```.
1. Generate tiles: 
 1. Open MapTiler 
 1. Choose Google Maps compatible > Continue
 1. Add > choose ```{GEOREFERENCED_PNG_FILE}```
 1. Set transparency for color white > Continue
 1. Choose WGS84 - Latitude and longitude  > Continue
 1. Choose zoom levels > choose JPEG as file format > Continue
 1. Choose output directory for tiles (```raster/places/{PLACE}/{YEAR}```) > Continue
 1. Choose Google Maps and OpenLayers > Continue > Continue > Render
1. Add ```<layer type="tms" year="{YEAR}" bounds="{WEST_SOUTH_EAST_NORTH}"/>``` to [```vector/places/{PLACE}/layers.xml```](https://github.com/l6gistaja/vanalinnad/blob/master/vector/places/Tallinn/layers.xml). You can get boundingbox from line ```mapBounds = new OpenLayers.Bounds({WEST,SOUTH,EAST,NORTH});``` from file [```raster/places/{PLACE}/{YEAR}/tiles/openlayers.html```](https://github.com/l6gistaja/vanalinnad/blob/master/raster/places/Tallinn/1968/tiles/openlayers.html).
1. Run ```./dev/postproc.bash {PLACE} {YEAR}``` from ```{VANALINNAD_ROOT_DIR}```
1. Add map description to [```vector/places/{PLACE}/rss{YEAR}.xml```](https://github.com/l6gistaja/vanalinnad/blob/master/vector/places/Tallinn/rss1968.xml). You can use [```vector/rsstemplate.xml```](https://github.com/l6gistaja/vanalinnad/blob/master/vector/rsstemplate.xml) as template. Extra tag legends is comma separated list of legend image filenames under [```legends/places/{PLACE}/```](https://github.com/l6gistaja/vanalinnad/tree/master/legends/places/Tallinn).

### Merging multiple historical maps into one map

Prev. ch. means previous chapter "Adding new historical map" here.

1. Create multiple maps (prev. ch. steps 1-3) as subdirectories in writable directory ```{MERGE_DIR}```.
1. Using template below, create  ```vector/places/{PLACE}/bbox{YEAR}.kml```. If you want to hide merger lines at lower zoom levels, try to add ```<Data name="montage"><value>yes</value></Data>``` to ```<ExtendedData>```.
1. Run ```./dev/mixer.pl {PLACE} {YEAR}``` from ```{VANALINNAD_ROOT_DIR}```
1. Prev. ch. step 4. Boundingbox value can be extracted from ```vector/places/{PLACE}/bbox{YEAR}.kml```, from tag /ExtendedData/Data[@name=bbox]/value .
1. Prev. ch. step 6. You can add item for every used map.

Multimap BBox template: 

    <?xml version="1.0" encoding="UTF-8"?>
    <kml xmlns="http://www.opengis.net/kml/2.2">
    <Document>
    <ExtendedData>
    <Data name="sourcedir"><value>{MERGE_DIR}</value></Data>
    <Data name="maps"><value>{YEAR1_SUBDIR},{YEAR2_SUBDIR},...</value></Data>
    <Data name="zmin"><value>{MINIMUM_ZOOM_LEVEL}</value></Data>
    <Data name="zmax"><value>{MAXIMUM_ZOOM_LEVEL}</value></Data>
    <Data name="tileext"><value>.jpg</value></Data>
    </ExtendedData>
    </Document>
    </kml>