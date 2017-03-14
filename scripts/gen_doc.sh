#!/bin/bash

if [ $# -lt 2 ];
then
	echo "gen_doc.sh FlashR_man_dir FlashGraphR_man_dir"
	exit 1
fi

FlashR_mandir=$1
FlashGraphR_mandir=$2
echo $FlashR_mandir
echo $FlashGraphR_mandir

echo "tools::Rdindex(\"$FlashR_mandir\", \"/tmp/index.Rd\", width=200)" | R --no-save
perl scripts/gen_index.pl /tmp/index.Rd pages/FlashR-API.md FlashR
echo "tools::Rdindex(\"$FlashGraphR_mandir\", \"/tmp/index.Rd\", width=200)" | R --no-save
perl scripts/gen_index.pl /tmp/index.Rd pages/FlashGraphR-API.md FlashGraphR
mkdir -p FlashR-API
for file in `ls $FlashR_mandir`
do
	input_file="$FlashR_mandir/$file"
	output_file="FlashR-API/${file}.html"
	echo "tools::Rd2HTML(\"$input_file\", out=\"$output_file\")" | R --no-save
done

mkdir -p FlashGraphR-API
for file in `ls $FlashGraphR_mandir`
do
	input_file="$FlashGraphR_mandir/$file"
	output_file="FlashGraphR-API/${file}.html"
	echo "tools::Rd2HTML(\"$input_file\", out=\"$output_file\")" | R --no-save
done
