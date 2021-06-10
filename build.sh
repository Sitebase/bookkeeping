#!/bin/bash
# open "mailto:dirk@trivius.be?subject=Sitebase documenten&body=Beste Dirk,In bijlage mijn documenten voor vorige maand."

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#cd $DIR

#cd .. # PDF are in sub folders of the parent folder
cd "./documents"

echo $DIR
# config
prefix=$(date -d "-1 month" +%Y-%m)
output_folder="backup"

red='\033[0;31m'
green='\033[0;32m'
purple='\033[0;35m' 
NC='\033[0m' # No Color

merge_pdf() {
    output=$1
    in=$2
    pdfunite $in*.pdf $output
}

detect_unsupported_documents() {
    docs=$(find . -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) -not -path "*/.automation/*")
    if [[ $docs != "" ]]; then
        echo -e "${red}ERROR${NC} found non supported document extension, make sure to convert these to PDF first:";
        echo -e "$docs"
        exit -1
    fi
}

# rename PDF files that don't have the prefix using the 
# current prefix
# this means that incorrectly named PDF files will automatically be included
# in the bookkeeping for the current running prefix (previous month)
rename_missing_prefix() {
    prefix=$1
    invalid_files=$(find . -iname "*.pdf" -type f | grep -v -E '\/[0-9]{4}-[0-9]{2}-')
    #echo $invalid_files | while read f; do
    for f in $invalid_files; do
        dir=$(dirname $f)
        file=$(basename $f | tr '[:upper:]' '[:lower:]')
        echo -e "${green}RENAME${NC} $f => $dir/$prefix-$file"
        mv $f "$dir/$prefix-$file"
    done
}

#h_subfolders() {
    #path=$1
    #subdircount=`find $path/* -maxdepth 1 -type d | wc -l`

    #echo "--> $subdircount"
    #if [ $subdircount -eq 0 ]
    #then
        #echo "none"
        #return false 
    #else
        #echo "hassubdirs"
        #return true 
    #fi
#}

combine_pdf_with_prefix() {
    prefix=$1
    p=$2
    output="$output_folder/$prefix-$p.pdf"
    result=$(find $p -name "$prefix*.pdf")

    if [[ $result = "" ]]; then
        echo -e "${green}MERGE${NC} no PDF documents found in folder '$p'"
        return
    fi

    echo -e $result

    subfolder_count=$(find $p/* -maxdepth 1 -type d | wc -l)
    if [[ $subfolder_count -gt 0 ]]; then
        echo -e "${green}MERGE${NC} documents in folder $p => $output ${purple}[subfolders]${NC}"
        merge_pdf "$output" "$p/*/$prefix"
    else 
        echo -e "${green}MERGE${NC} documents in folder $p => $output"
        merge_pdf "$output" "$p/$prefix"
    fi
}

mkdir -p $output_folder

echo -e "${green}RUN${NC} do bookkeeping for files with prefix ${purple}$prefix${NC}"
detect_unsupported_documents
rename_missing_prefix "$prefix"
combine_pdf_with_prefix "$prefix" "excerpt"
combine_pdf_with_prefix "$prefix" "in"
combine_pdf_with_prefix "$prefix" "out"
combine_pdf_with_prefix "$prefix" "personal"
combine_pdf_with_prefix "$prefix" "documents"

echo -e "${green}READY${NC}"
