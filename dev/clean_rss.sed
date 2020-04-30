# Clean up all RSS files:
#     find vector/places/ -name "rss*.xml" -exec sed -f dev/clean_rss.sed -i {} \;
# Clean up certain RSS file:
#     sed -f dev/clean_rss.sed -i RSS_FILE

# first delete all empty tags, afterwards handlemore specific cases
/^<[^\/][^<>]*><\/[^<>]*>$/d
/^<copyright>0<\/copyright>$/d
/^<guid>isbn=;nlib\.ee=<\/guid>$/d
/^<componentsregexp>\^1<\/componentsregexp>$/d
