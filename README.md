# vanalinnad

Historical maps of Estonian cities under grid of today's street network.

* License: [BSD 2-clause License](http://openlayers.org/dev/license.txt), inherited from used [OpenLayers](http://openlayers.org) library
* Vector data: © [OpenStreetMap contributors](http://www.openstreetmap.org/copyright)
* Tiles and initial JavaScript: [MapTiler](http://www.maptiler.org/)/[GDAL2Tiles](http://www.klokan.cz/projects/gdal2tiles/), © 2008 [Klokan Petr Pridal](http://www.klokan.cz/), [GDAL](http://www.gdal.org/) & [OSGeo](http://www.osgeo.org/) [GSoC](http://code.google.com/soc/)
* GitHub: [https://github.com/l6gistaja/vanalinnad](https://github.com/l6gistaja/vanalinnad)
* Author: juks at alkohol ee

## Map URL examples

1. [index.html?site=Tallinn](index.html?site=Tallinn) : all maps of Tallinn.
1. [index.html?site=Tallinn&year=1968](index.html?site=Tallinn&year=1968) : Tallinn in year 1968.
1. [index.html?site=Tallinn&year=1968&zoom=15&lat=59.43736&lon=24.78081](index.html?site=Tallinn&year=1968&zoom=15&lat=59.43736&lon=24.78081) : Tallinn in year 1968, Kadriorg area.
1. [index.html?site=Tallinn&year=1968&zoom=15&lat=59.43736&lon=24.78081&years=1968.1911.1885.1856](index.html?site=Tallinn&year=1968&zoom=15&lat=59.43736&lon=24.78081&years=1968.1911.1885.1856) : Tallinn in year 1968, Kadriorg area. Selectable are maps only from years 1968, 1911, 1885 and 1856.

Hint: for debug mode, append ```&debug=1``` to URLs.

## Adding new data to application

Following describes data adding process with Debian Linux 6.0.8.

### Dependencies

1. Create writable directory ```{VANALINNAD_ROOT_DIR}/cache```
1. Install [GDAL utils](http://www.gdal.org/) and [markdown](http://daringfireball.net/projects/markdown/) (```sudo apt-get install gdal-bin markdown```)
1. Install [MapTiler](http://www.maptiler.org/)
1. Install [ImageMagick](http://www.imagemagick.org)
1. Install missing Perl modules (```sudo cpan XML::Simple JSON Storable Math::Round```)

### Adding new historical map

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

### Adding road layers from OpenStreetMap

If not already installed, ```apt-get install wget``` .

1. ```cd {VANALINNAD_ROOT_DIR}```
1. ```./dev/postproc.bash {PLACE} {SOME_EXISTING_YEAR} | grep 'BBox max'```
1. Add boundingbox from previous step to ```dev/osm2xml/roads.kml```, into tag /Placemark[0]/LineString/coordinates
1. ```cd dev/osm2xml/ ; ./generate_roads.pl | bash```
1. Original KML files roads0.kml ... roads4.kml were generated into ```{VANALINNAD_ROOT_DIR}/cache/```. You can merge those files into fewer files.
1. For every {SOURCE_KML} created in previous step: ```../kml_minify.pl .00001 ../../cache/{SOURCE_KML} ../../vector/places/{PLACE}/{FINAL_KML}```
1. For every {FINAL_KML} created in previous step, add tag ```<layer type="roads" name="{LAYER_NAME}" file="{FINAL_KML}" maxres="{MIN_ZOOM_LEVEL}"/>``` to ```{VANALINNAD_ROOT_DIR}/vector/places/{PLACE}/layers.xml```


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