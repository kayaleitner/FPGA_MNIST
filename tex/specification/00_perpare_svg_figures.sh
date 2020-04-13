#! /bin/bash

echo $(pwd)

SVG_DIR="./img/inkscape"




# Collect all SVG files
SVG_FILES=$(find img/inkscape  -name "*.svg")
echo $SVG_FILES

for svg_file in $SVG_FILES
do
    # echo $svg_file
    filename=$(basename -- "$svg_file")
    echo $filename
    # Execute Inkscape
    inkscape -D -z --file=$svg_file --export-pdf="img/inkpdf/${filename}.pdf" --export-latex
done
