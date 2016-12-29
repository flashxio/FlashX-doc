#!/bin/bash

mandir=$1
echo $mandir

mkdir -p FlashR-API
for file in `ls $mandir`
do
	input_file="$mandir/$file"
	output_file="FlashR-API/${file}.html"
	echo "tools::Rd2HTML(\"$input_file\", out=\"$output_file\")" | R --no-save
done
