# vanalinnad

Historical maps of Estonian cities under the grid of today's street network.

**Shortcut keys:** F11 enables/disables fullscreen. By OpenLayers defaults arrow keys pan, +/- keys zoom & Page Up/Page Down/Home/End scroll by three quarters of a page. Additionally, comma (,) displays next and period (.) will display previous historical map.

<table id="readme_legends">
    <tr>
        <th>Era</th>
        <th>Legend explanations</th>
    </tr>
    <tr>
        <td>< 1900</td>
        <td style="text-align:center"><a target="_blank" href="http://www.ra.ee/kaardid/index.php/et/site/page?view=symbols">et/sv/ru</a></td>
    </tr>
    <tr>
        <td style="text-align:center"><a target="_blank" href="http://geoportaal.maaamet.ee/est/Teenused/Kaardirakendused/Ajalooliste-kaartide-rakendus-p157.html">~ 1900</a></td>
        <td style="text-align:center"><a target="_blank" href="https://geoportaal.maaamet.ee/docs/WMS/Riigikaitseopetuse_kasiraamat_kesk-ja_kutsekoolidele_1933.jpg?t=20170418094625">et</a></td>
    </tr>
    <tr>
        <td style="text-align:center">~ 1918</td>
        <td style="text-align:center"><a target="_blank" href="info.html?site=Rakvere&year=1922#map.1918">de</a></td>
    </tr>
    <tr>
        <td>~ 1925</td>
        <td style="text-align:center"><a target="_blank" href="https://www.digar.ee/viewer/et/nlib-digar:46362">et</a></td>
    </tr>
    <tr>
        <td><a target="_blank" href="http://geoportaal.maaamet.ee/est/Teenused/Kaardirakendused/Ajalooliste-kaartide-rakendus-p157.html">> 1940</a></td>
        <td style="text-align:center">ru: <a target="_blank" href="https://geoportaal.maaamet.ee/docs/WMS/NL_topo_10T_leppemargid__1977.pdf?t=20141126102828">1:10k</a>, <a target="_blank" href="https://geoportaal.maaamet.ee/docs/WMS/NL_topo_10T_25T_leppemargid_1966.pdf?t=20111212103321">1:10...25k</a>, <a target="_blank" href="https://geoportaal.maaamet.ee/docs/WMS/NL_topo_25T_50T_100T_leppemargid_1953.pdf?t=20111212103315">1:25...100k</a></td>
    </tr>
</table>

* License: BSD 2-clause License, inherited from used [OpenLayers 2](http://openlayers.org) library
* Vector data: © [OpenStreetMap contributors](http://www.openstreetmap.org/copyright)
* Tiles and initial JavaScript: [MapTiler](http://www.maptiler.org/)/[GDAL2Tiles](http://www.klokan.cz/projects/gdal2tiles/), © 2008 [Klokan Petr Pridal](http://www.klokan.cz/), [GDAL](http://www.gdal.org/) & [OSGeo](http://www.osgeo.org/) [GSoC](http://code.google.com/soc/)
* WMS: [Maa-amet](vector/wms/maaamet.html)
* Auxiliary frontpage tiles: [Bing Maps](http://www.bing.com/maps/)
* GitHub: [https://github.com/l6gistaja/vanalinnad](https://github.com/l6gistaja/vanalinnad)
* Author: juks at alkohol ee

## Map URL examples

1. [index.html?site=Tallinn](index.html?site=Tallinn) : all maps of Tallinn.
1. [index.html?site=Tallinn&year=1968](index.html?site=Tallinn&year=1968) : Tallinn in year 1968.
1. [index.html?site=Tallinn&year=1968&zoom=15&lat=59.43736&lon=24.78081](index.html?site=Tallinn&year=1968&zoom=15&lat=59.43736&lon=24.78081) : Tallinn in year 1968, Kadriorg area.
1. [index.html?site=Tallinn&year=1968&zoom=15&lat=59.43736&lon=24.78081&years=1968.1911.1885.1856](index.html?site=Tallinn&year=1968&zoom=15&lat=59.43736&lon=24.78081&years=1968.1911.1885.1856) : Tallinn in year 1968, Kadriorg area. Selectable are maps only from years 1968, 1911, 1885 and 1856.
1. [index.html?wms=maaamet&zoom=8&convert=EPSG\_4326~EPSG\_3301~24.78081~59.43736&marker=R](index.html?wms=maaamet&zoom=8&convert=EPSG_4326~EPSG_3301~24.78081~59.43736&marker=R) : Fresh Maa-amet map, ```&marker=R``` adds marker to the center of map.

Hints:

1. for debug mode, append ```&debug=1``` to URLs.
1. if you add ```&draw=KML``` or ```&draw=GPX``` to urls, you can draw and export KML or GPX tracks.

## Adding new data to application

Following describes data adding process with Debian Linux 8.4.

### Dependencies

1. Create writable directory ```{VANALINNAD_ROOT_DIR}/cache```
1. Download [GDAL 1.11.3](https://trac.osgeo.org/gdal/wiki/DownloadSource)
1. Unpack and install it: ```./configure ; make ; sudo make install```
1. Install [markdown](http://daringfireball.net/projects/markdown/) and [ImageMagick](http://www.imagemagick.org) etc (```sudo apt-get install markdown imagemagick python-gdal xsltproc osmctools wget```)
1. If neccessary: ```sudo ln -s /usr/lib/libproj.so.0 /usr/lib/libproj.so```
1. Install missing Perl modules (```sudo cpan XML::Simple JSON Storable Math::Round DBD::SQLite``` or ```apt-get install libxml-simple-perl libjson-perl libstorable-perl libmath-round-perl libdbi-perl libdbd-sqlite3-perl```)

### Main scripts

* **dev/devserver.pl** : start development server.
* **dev/finishmap.bash** : cleanup project and upload last changes.
* **dev/newsite/newsite.pl** : generate scaffolding for new site.
* **dev/osm2xml/allosmroads.pl** : download and update new road networks for all sites.
* **dev/osm2xml/osmroads.pl** : download and update new road networks for a certain site.
* **dev/osm2xml/regenerate_vectors.bash** : regenerate vector maps from source KMLs.
* **dev/readme/md2html.bash** : generate new readme.html after changes in README.md.
* **dev/shapeimporter.pl** : import other vector maps from data downloaded by dev/osm2xml/* and specified by vector/places/{SITE}/*.xslt.
* **dev/tiler.pl** : generate map tiles, and if necessary, merge them with other composite map tiles.

### Deleting map

1. delete map directory from raster/places/{SITE}
1. remove corresponding layer tag from vector/places/{SITE}/layers.xml
1. add flag flags="deleted" to corresponding translate tag in vector/places/{SITE}/gdal.xml
1. run dev/finishmap.bash

### Creating new site

Run ```dev/newsite/newsite.pl {SITE}``` . Add new ```<Placemark>``` with ```<name>{SITE}</name>``` to vector/selector.kml to make new site visible on main page. NB! Dont use symbols outside standard latin alphabet in {SITE}, it will be included in catalogue names. You can add "real name" into ```/Document/Placemark[x]/description``` @ vector/selector.kml and into ```/city``` @ vector/places/{SITE}/layers.xml .

### Adding new historical map to site

In following, {SOURCE_FILE_DIR} is /dirsource from conf.xml.

1. Cut away and whiten original maps edges, legends, empty areas etc. It makes tile generation speed, repo size and download speed smaller.
1. Save this file as {SOURCE_FILE} to:
 1. ```{SOURCE_FILE_DIR}/places/{SITE}/composed/{COMPOSITE_YEAR}```, if new map is composite (composed from more then one map).
 1. ```{SOURCE_FILE_DIR}/places/{SITE}```, if new map is NOT composite.
1. Georeference image @ vector/places/{SITE}/gdal.xml . In following, {GEOREFERENCE} is at last 3 GCPs in form ```-gcp {X_COORDINATE_OF_GCP_ON_SOURCE_IMAGE} {Y_COORDINATE_OF_GCP_ON_SOURCE_IMAGE}``` ```{EAST_COORDINATE_OF_GCP} {NORTH_COORDINATE_OF_GCP} ```. For example, GCPs can be narrow crossroads which are on both historic and modern maps. You can use [index.html?debug=1](index.html?debug=1) for finding GCPs geographical coordinates and [dev/pixelpicker.html](dev/pixelpicker.html) for finding GCP pixel coordinates.
 1. If new map is composite, add ```<translate map="{YEAR}" composite="{COMPOSITE_YEAR}"><t file="{SOURCE_FILE}" gcps="{GEOREFERENCE}"/></translate>``` and ```<composite id="{COMPOSITE_YEAR}" maps="{YEAR}" montage="yes"/>``` to gdal.xml. Later, new composite map years can be added to attribute ```maps```, separated by comma. NB! Order of this list decides, how component maps overwrite eachother. Remove attribute montage="yes", when component maps dont touch eachother.
 1. If new map is NOT composite, add ```<translate map="{YEAR}"><t file="{SOURCE_FILE}" gcps="{GEOREFERENCE}"/></translate>``` to gdal.xml.
1. Run ```dev/tiler.pl -s {SITE} -y {YEAR}```. (If you for some reason dont want to generate map tiles but still want to generate misc data files, add -r flag.) NB! Only last ```<t>``` from ```<translate>``` added in previous step is taken into account while rendering tiles.

### Adding road layers from OpenStreetMap

1. Bounds of road layers can be determined by adding tag ```<roadbounds w="..." s="..." e="..." n="..."/>``` to ```{VANALINNAD_ROOT_DIR}/vector/places/{SITE}/layers.xml```. If this tag or some of its coordinates are missing, other boundaries are calculated from maximum values of tile layers in ```{VANALINNAD_ROOT_DIR}/vector/places/{SITE}/layers.xml```.
1. For every road layer which will be created, add tag ```<layer type="roads" name="{LAYER_NAME}" file="{KML_FILENAME}" maxres="{MIN_ZOOM_LEVEL}" levels="{LEVEL_LIST}"/>``` to ```{VANALINNAD_ROOT_DIR}/vector/places/{SITE}/layers.xml```. {LEVEL_LIST} is comma separated list of numbers from 0 to 5.
1. Run ```./dev/osm2xml/osmroads.pl {SITE} .00001```
 1. If original OSM data is too big, process might stall. In case you need only highways from OpenStreetMap, add highway as 3rd parameter: ```./dev/osm2xml/osmroads.pl {SITE} .00001 highway```
 
You can update existing road layers by running ```./dev/osm2xml/allosmroads.pl``` .

License
-------

Copyright 2013-2020, juks at alkohol ee. All rights reserved.

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
