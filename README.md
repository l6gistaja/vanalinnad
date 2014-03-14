vanalinnad
==========

Historical maps of Tallinn under grid of today's street network.

* License: [BSD 2-clause License](http://openlayers.org/dev/license.txt), inherited from used [OpenLayers](http://openlayers.org) library
* Vector data: © [OpenStreetMap contributors](http://www.openstreetmap.org/copyright)
* GitHub: [https://github.com/l6gistaja/vanalinnad](https://github.com/l6gistaja/vanalinnad)
* Author: juks at alkohol ee

Adding new historical map to application
----------------------------------------

Following describes new map adding process with Debian Linux 6.0.8.

1. Optionally, cut away (or whiten) edges, legends, empty areas etc from original map. It makes tile generation speed, repo size and download speed smaller.
1. Install [GDAL utils](http://www.gdal.org/) (in Debian: ```apt-get install gdal-bin```)
1. [Georeference](https://github.com/l6gistaja/vanalinnad/blob/master/raster/places/Tallinn/1968/gdal.txt) source map image: ```gdal_translate {SOURCE_IMAGE_FILE}  {GEOREFERENCED_PNG_FILE} -of PNG ``` ```-gcp {X_COORDINATE_OF_GCP_ON_SOURCE_IMAGE} {Y_COORDINATE_OF_GCP_ON_SOURCE_IMAGE}``` ```{EAST_COORDINATE_OF_GCP} {NORTH_COORDINATE_OF_GCP}```. Choose and specify image (in pixels) and geographical coordinates of at least 3 G(round)C(ontrol)P(oint)s. For example, GCPs can be narrow crossroads which are on both historic and modern maps. You can use ```dev/coords.html``` for finding GCPs geographical coordinates.
1. Install [MapTiler](http://www.maptiler.org/)
1. Generate tiles: open MapTiler > choose Google Maps compatible > Continue > Add > choose ```{GEOREFERENCED_PNG_FILE}``` > Continue > choose WGS84 - Latitude and longitude  > Continue > choose zoom levels > choose JPEG as file format > Continue > choose output directory for tiles (```raster/places/{PLACE}/{YEAR}/tiles```) > Continue > choose Google Maps and OpenLayers > Continue > Continue > Render
1. Optionally, throw away empty tiles:  ```cd dev/jpg2png/ ; ./replace.bash ../../raster/places/{PLACE}/{YEAR}/tiles/```. For that step you need [ImageMagick](http://www.imagemagick.org)
1. Add ```<layer type="tms" year="{YEAR}" bounds="{WEST_SOUTH_EAST_NORTH}"/>``` to [```vector/places/{PLACE}/layers.xml```](https://github.com/l6gistaja/vanalinnad/blob/master/vector/places/Tallinn/layers.xml). You can get boundingbox from line ```mapBounds = new OpenLayers.Bounds({WEST,SOUTH,EAST,NORTH});``` from file [```raster/places/{PLACE}/{YEAR}/tiles/openlayers.html```](https://github.com/l6gistaja/vanalinnad/blob/master/raster/places/Tallinn/1968/tiles/openlayers.html).
1. Regenerate BBoxes info: ```dev/genbbox.pl {VANALINNAD_ROOT_DIR} {PLACE}```
1. Optionally, add map description to [```vector/places/{PLACE}/rss{YEAR}.xml```](https://github.com/l6gistaja/vanalinnad/blob/master/vector/places/Tallinn/rss1968.xml). You can use [```vector/rsstemplate.xml```](https://github.com/l6gistaja/vanalinnad/blob/master/vector/rsstemplate.xml) as template. Extra tag legends is comma separated list of legend image filenames under [```raster/places/{PLACE}/{YEAR}/```](https://github.com/l6gistaja/vanalinnad/tree/master/raster/places/Tallinn/1968).

License
-------

Copyright 2013-2014, juks at alkohol ee. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY juks at alkohol ee ``AS IS'' AND ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of juks at alkohol ee.