<?php 

error_reporting(E_ALL);
ini_set('display_errors', 1);

echo file_get_contents('https://nominatim.openstreetmap.org/search?'.$_SERVER['QUERY_STRING'], false,stream_context_create(array("ssl"=>array("verify_peer"=>false,"verify_peer_name"=>false))));

/*  
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'https://nominatim.openstreetmap.org/search?'.$_SERVER['QUERY_STRING']);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, 1);
curl_setopt($ch, CURLOPT_HEADER, 0);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
echo $html_content = curl_exec($ch);
curl_close($ch);
*/
