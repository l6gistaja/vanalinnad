<?php 
foreach(explode(",","7530,11170,9c40,13880,c350,15f90") as $b16) { echo $b16.' <sub>(16)</sub> =&gt; '.base_convert($b16,16,36).' <sub>(36)</sub><br/>'; }

$c = 0;
$l = 0;
for($i=0;$i<100000;$i++) {
    #$b = base64_encode($i);
    #$b = dechex($i);
    $b = base_convert($i,10,36);
    $f = '0.'.str_pad (''.$i, 5, '0',STR_PAD_LEFT);
    $t = $f.' '.$b;
    $l += strlen($f)-strlen($b);
    if(strlen($b) > strlen($f)) {
        $c++;
        
        
    }
    echo $t.'<br/>';
}
echo $c.'; '.$l;
