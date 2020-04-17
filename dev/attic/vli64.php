<?php

$vli64 = [];
$b36 = [];
for($i = 0; $i < 100000; $i++) {
    $vli64[] = encode_vli64($i);
    $b36[] = base_convert($i, 10, 36);
}

function encode_vli64($int) {
    $y = '';
    do {
        $m = $int %64;
        $y .= ($m == 44 ? 'p' : chr(48 + $m));
        $int >>= 6;
    } while ($int);
    return $y;
}

?>
<pre>
<script>

function decode_vli64(str) {
    var y = 0;
    var i = 0;
    for(; i < str.length; i++) {
        c = str.charCodeAt(i);
        y += (c == 112 ? 44 : c - 48) << (6*i);
    }
    return y;
}

vli64 = <?php echo json_encode($vli64); ?>;
b36 = <?php echo json_encode($b36); ?>;
vli64d = [];
b36d = [];
vli64l = vli64.length - 1;
b36l = vli64.length - 1;

startv = Date.now();
for(i in vli64) { vli64d.push(decode_vli64(vli64[i])); }
vli64t = Date.now() - startv;

startb = Date.now();
for(i in b36) { b36d.push(parseInt(b36[i],36)); }
b36t = Date.now() - startb;

document.writeln('Decoding speeds: vli64 : ' + vli64t + ' ms ; base36 ' + b36t + " ms\n");

document.writeln("vli64: source integer - encoded integer - re-decoded integer - base36 :\n");

for(i in vli64) {
    document.writeln(i + ' - ' + vli64[i].replace(/&/g, "&amp;")
         .replace(/</g, "&lt;")
         .replace(/>/g, "&gt;")
         .replace(/"/g, "&quot;")
         .replace(/'/g, "&#039;") + ' - ' + vli64d[i] + ' - ' + b36[i] +"\n");
    vli64l += vli64[i].length;
    b36l += b36[i].length;
}
document.writeln('Encoding lengths: vli64 : ' + vli64l + ' bytes ; base36 ' + b36l + " bytes\n");
</script>
</pre>
