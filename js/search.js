if (!vlSearch) {
    var vlSearch = {};
}

vlSearch.searchFocus = function () {
    document.forms[0].elements[0].focus();
}

vlSearch.setResults = function(content) {
    document.getElementById('searchresults').innerHTML = content;
}

vlSearch.ieVer = function(){  
    var iev=0;
    var ieold = (/MSIE (\d+\.\d+);/.test(navigator.userAgent));
    var trident = !!navigator.userAgent.match(/Trident\/7.0/);
    var rv=navigator.userAgent.indexOf("rv:11.0");
    if (ieold) iev=new Number(RegExp.$1);
    if (navigator.appVersion.indexOf("MSIE 10") != -1) iev=10;
    if (trident&&rv!=-1) iev=11;
    return iev;         
}

vlSearch.searchPlace = function (place) {
    if (/\S/.test(place)) {
        vlSearch.setResults('Searching...');
        OpenLayers.Request.GET({
            url: (vlSearch.ieVer() 
                    ? 'http://vanalinnad.mooo.com/proxy.php'
                    : 'http://nominatim.openstreetmap.org/search')
                + '?format=json&countrycodes=ee&q=' + encodeURIComponent(place),
            callback: vlSearch.searchLoadPlaces
        });
    }
}

vlSearch.searchLoadPlaces = function(request) {
    var results = '';
    if(request.status == 200) {
        var title;
        var bbox;
        var json = JSON.parse(request.responseText);
        for(var i = 0; i < json.length; i++) {
            bbox = json[i].boundingbox[2] + ','
                + json[i].boundingbox[0] + ','
                + json[i].boundingbox[3] + ','
                + json[i].boundingbox[1];
            title = ' title="' + (json[i].class + ': ' + json[i].type).replace(/_+/g, ' ') + '"';
            results += '<li><img src="'
                + ('icon' in json[i] ? json[i].icon : 'raster/icons/placemark.png') + '"' + title
                + '/> <a target="_blank" onclick="return map.zoomToBBox([' + bbox
                + ']);" href="http://www.openstreetmap.org/?bbox=' + bbox
                + '"' + title + '>' + json[i].display_name.replace(/, Estonia$/, '') + '</a></li>';
        }
        results = (results != '') ? '<ol>' + results + '</ol>'
            : '<br/>Search found nothing.';
    } else {
        results = '<br/>AJAX error, request status code ' + request.status;
    }
    vlSearch.setResults(results);
    vlSearch.searchFocus();
}

vlSearch.searchEmpty = function(b) {
    b.form.q.value='';
    vlSearch.setResults('');
    vlSearch.searchFocus();
}

vlSearch.toggleSearch = function() {
    var e = document.getElementById('searchDiv');
    if ( e.style.display == 'none' )
        e.style.display = 'block';
    else
        e.style.display = 'none';
    vlSearch.searchFocus();
}

vlSearch.handleKeystrokes = function(event, b) {
    switch(event.keyCode) {
        case 46:
        case 190:
        case 44:
        case 188: return false;
        case 13:
            b.form.s.click();
            return false;
        default: return true;
    }
}
