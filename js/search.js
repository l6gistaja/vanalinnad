if (!vlSearch) {
    var vlSearch = {};
}

vlSearch.searchPlace = function (place) {
    if (/\S/.test(place)) {
        OpenLayers.Request.GET({ 
            url: 'http://nominatim.openstreetmap.org/search?format=json&countrycodes=ee&q='+place,
            callback: vlSearch.searchLoadPlaces
        });
    }
}

vlSearch.searchLoadPlaces = function(request) {
    var results = '';
    if(request.status == 200) {
        var title;
        var bbox;
        var bboxes = [];
        var json = JSON.parse(request.responseText);
        for(var i = 0; i < json.length; i++) {
            bbox = json[i].boundingbox[2]+','+json[i].boundingbox[0]
                + ( (json[i].boundingbox[0] != json[i].boundingbox[1]) && (json[i].boundingbox[2] != json[i].boundingbox[3])
                    ? ','+json[i].boundingbox[3]+','+json[i].boundingbox[1] : '');
            if(OpenLayers.Util.indexOf(bboxes, bbox) < 0) {
                bboxes.push(bbox);
            } else {
                continue;
            }
            title = ' title="' + (json[i].class + ': ' + json[i].type).replace(/_+/g, ' ') + '"';
            results += '<li><img src="'
                + ('icon' in json[i] ? json[i].icon : 'raster/icons/placemark.png') + '"' + title
                + '/> <a target="_blank" href="http://www.openstreetmap.org/?bbox='
                + bbox
                + '"' + title + '>' + json[i].display_name.replace(/, Estonia$/, '') + '</a></li>';
        }
        results = (results != '') ? '<ol>' + results + '</ol>'
            : '<br/>Search found nothing.';
    } else {
        results = '<br/>AJAX error, request status code ' + request.status;
    }
    document.getElementById('searchresults').innerHTML = results;
}

vlSearch.searchEmpty = function(b) {
    b.form.q.value='';
    document.getElementById('searchresults').innerHTML='';
}