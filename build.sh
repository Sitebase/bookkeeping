DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
cd .. # PDF are in sub folders of the parent folder

# config
prefix=$(date -v-1m +%Y-%m)
output_folder="backup"

red='\033[0;31m'
green='\033[0;32m'
purple='\033[0;35m' 
NC='\033[0m' # No Color

merge_pdf() {
    output=$1
    in=$2
    "/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py" -o $output $in
}

detect_unsupported_documents() {
    docs=$(find . -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) -not -path "./.automation/*")

    if [[ $docs != "" ]]; then
        echo "${red}ERROR${NC} found non supported document extension, make sure to convert these to PDF first:";
        echo "$docs"
        exit -1
    fi
}

# rename PDF files that don't have the prefix using the 
# current prefix
# this means that incorrectly named PDF files will automatically be included
# in the bookkeeping for the current running prefix (previous month)
rename_missing_prefix() {
    prefix=$1
    invalid_files=$(find . -name "*.pdf" -type f | grep -v -E '\/[0-9]{4}-[0-9]{2}-')
    for f in $invalid_files
    do
        dir=$(dirname $f)
        file=$(basename $f)
        echo "${green}RENAME${NC} $f => $dir/$prefix-$file"
        mv $f "$dir/$prefix-$file"
    done
}

h_subfolders() {
    path=$1
    subdircount=`find $path/* -maxdepth 1 -type d | wc -l`

    echo "--> $subdircount"
    if [ $subdircount -eq 0 ]
    then
        echo "none"
        return false 
    else
        echo "hassubdirs"
        return true 
    fi
}

combine_pdf_with_prefix() {
    prefix=$1
    path=$2
    output="$output_folder/$prefix-$path.pdf"

    result=$(find $path -name $prefix*.pdf)

    if [[ $result = "" ]]; then
        echo "${green}MERGE${NC} no PDF documents found in folder '$path'"
        return
    fi

    subfolder_count=$(find $path/* -maxdepth 1 -type d | wc -l)
    if [[ $subfolder_count -gt 0 ]]; then
        echo "${green}MERGE${NC} documents in folder $path => $output ${purple}[subfolders]${NC}"
        merge_pdf "$output" "$path/*/$prefix*.pdf"
    else 
        echo "${green}MERGE${NC} documents in folder $path => $output"
        merge_pdf "$output" "$path/$prefix*.pdf"
    fi
}

mkdir -p $output_folder

echo "${green}RUN${NC} do bookkeeping for files with prefix ${purple}$prefix${NC}"
detect_unsupported_documents
rename_missing_prefix "$prefix"
combine_pdf_with_prefix "$prefix" "excerpt"
combine_pdf_with_prefix "$prefix" "in"
combine_pdf_with_prefix "$prefix" "out"
combine_pdf_with_prefix "$prefix" "personal"
combine_pdf_with_prefix "$prefix" "documents"

echo "${green}READY${NC}"
