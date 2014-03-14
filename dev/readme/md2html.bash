cat README.md | markdown > readme.html.bak
cat dev/readme/header.txt readme.html.bak dev/readme/footer.txt > readme.html
rm readme.html.bak

