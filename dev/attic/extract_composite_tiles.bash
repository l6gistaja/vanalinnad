for site in `ls -1 ~/Dropbox/vanalinnad_src/` ; do
    for composite in ~/Dropbox/vanalinnad_src/"$site"/composed/*/ ; do
        destination="${composite/\/home\/jux\/Dropbox\/vanalinnad_src\//\/home\/jux\/histmaps\/places\/}"
        mkdir -p "$destination"
        for map in "$composite"*/ ; do
            echo "$map"
            mv "$map" "$destination"
        done
        rm "$composite"tiletransparent.png
        rm "$composite"tilewritable.jpg
    done
done
