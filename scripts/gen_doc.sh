#!/bin/bash

if [ $# -lt 1 ];
then
	echo "gen_doc.sh man_dir"
	exit 1
fi

mandir=$1
echo $mandir

echo "tools::Rdindex(\"$mandir\", \"/tmp/index.Rd\", width=200)" | R --no-save
perl scripts/gen_index.pl /tmp/index.Rd pages/FlashR-API.md
mkdir -p FlashR-API
for file in `ls $mandir`
do
	input_file="$mandir/$file"
	output_file="FlashR-API/${file}.html"
	echo "tools::Rd2HTML(\"$input_file\", out=\"$output_file\")" | R --no-save
done
