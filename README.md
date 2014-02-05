vanalinnad
==========

Historical maps of Tallinn under grid of today's street network.

* Author: juks at alkohol ee
* License: [BSD 3-Clause License](http://www.opensource.org/licenses/BSD-3-Clause)

Adding new historical map to application
----------------------------------------

* Install [GDAL utils](http://www.gdal.org/) (in Debian: ```apt-get install gdal-bin```)
* [Georeference](https://github.com/l6gistaja/vanalinnad/blob/master/raster/places/Tallinn/1968/gdal.txt) source map image: ```gdal_translate {SOURCE_IMAGE_FILE}  {GEOREFERENCED_PNG_FILE} -of PNG ``` ```-gcp {X_COORDINATE_OF_GCP_ON_SOURCE_IMAGE} {Y_COORDINATE_OF_GCP_ON_SOURCE_IMAGE}``` ```{EAST_COORDINATE_OF_GCP} {NORTH_COORDINATE_OF_GCP}```. Choose and specify image (in pixels) and geographical coordinates of at least 3 G(round)C(ontrol)P(oint)s. For example, GCPs can be narrow crossroads which are on both historic and modern maps.
* Install [MapTiler](http://www.maptiler.org/)
* Generate tiles: open MapTiler > choose Google Maps compatible > Continue > Add > choose ```{GEOREFERENCED_PNG_FILE}``` > Continue > choose WGS84 - Latitude and longitude  > Continue > choose zoom levels > choose JPEG as file format > Continue > choose output directory for tiles (```raster/places/{PLACE}/{YEAR}/tiles```) > Continue > choose Google Maps and OpenLayers > Continue > Continue > Render
* Optionally, throw away empty tiles:  ```cd dev/jpg2png/ ; ./replace.bash ../../raster/places/{PLACE}/{YEAR}/tiles/```. For that step you need [ImageMagick](http://www.imagemagick.org)
* Add ```<layer type="tms" year="{YEAR}" bounds="{WEST_SOUTH_EAST_NORTH}"/>``` to [```vector/places/{PLACE}/layers.xml```](https://github.com/l6gistaja/vanalinnad/blob/master/vector/places/Tallinn/layers.xml). You can get boundingbox from line ```mapBounds = new OpenLayers.Bounds({WEST,SOUTH,EAST,NORTH});``` from file [```raster/places/{PLACE}/{YEAR}/tiles/openlayers.html```](https://github.com/l6gistaja/vanalinnad/blob/master/raster/places/Tallinn/1968/tiles/openlayers.html).
* Regenerate BBoxes info: ```dev/genbbox.pl {VANALINNAD_ROOT_DIR} {PLACE}```
* Optionally, add map description to [```vector/places/{PLACE}/rss{YEAR}.xml```](https://github.com/l6gistaja/vanalinnad/blob/master/vector/places/Tallinn/rss1968.xml). You can use [```vector/rsstemplate.xml```](https://github.com/l6gistaja/vanalinnad/blob/master/vector/rsstemplate.xml) as template. Extra tag legends is comma separated list of legend image filenames under [```raster/places/{PLACE}/{YEAR}/```](https://github.com/l6gistaja/vanalinnad/tree/master/raster/places/Tallinn/1968).
