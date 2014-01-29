vanalinnad
==========

Historical maps of Tallinn under grid of today's street network.

Author: juks ät alkohol ee
License: [BSD 3-Clause License](http://www.opensource.org/licenses/BSD-3-Clause)

Adding new historical map to application
----------------------------------------

* Install GDAL utils (in Debian: ```apt-get install gdal-bin```): http://www.gdal.org/
* Georeference source map image: ```gdal_translate {SOURCE_IMAGE_FILE}  {GEOREFERENCED_PNG_FILE} -of PNG ``` ```-gcp {X_COORDINATE_OF_GCP_ON_SOURCE_IMAGE} {Y_COORDINATE_OF_GCP_ON_SOURCE_IMAGE}``` ```{EAST_COORDINATE_OF_GCP} {NORTH_COORDINATE_OF_GCP}```. Choose and specify image (in pixels) and geographical coordinates of at least 3 G(round)C(ontrol)P(oint)s. For example, GCPs can be crossroads which are on both historic and modern maps. See: https://github.com/l6gistaja/vanalinnad/blob/master/raster/places/Tallinn/1968/gdal.txt
* Install MapTiler: http://www.maptiler.org/
* Generate tiles: open MapTiler > choose Google Maps compatible > Continue > Add > choose ```{GEOREFERENCED_PNG_FILE}``` > Continue > choose WGS84 - Latitude and longitude  > Continue > choose zoom levels > choose JPEG as file format > Continue > choose output directory for tiles (```raster/places/{PLACE}/{YEAR}/tiles```) > Continue > choose Google Maps and OpenLayers > Continue > Continue > Render
* Throw away empty tiles:  ```cd dev/jpg2png/ ; ./replace.bash ../../raster/places/{PLACE}/{YEAR}/tiles/```. For that step you need ImageMagick: http://www.imagemagick.org
* Add ```<layer type="tms" year="{YEAR}" bounds="{WEST_SOUTH_EAST_NORTH}"/>``` to ```vector/places/{PLACE}/layers.xml```. Boundingbox {WEST_SOUTH_EAST_NORTH} values are tag's BoundingBox values from ```raster/places/{PLACE}/{YEAR}/tiles/tilemapresource.xml```.
