#!/bin/bash

BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
MD_DIR="${BASEDIR}/src"
OUTPUT="${BASEDIR}/graphs"

function generate {
  local absoluteName
  local mdDir
  local outputDir

  absoluteName="$1"
  mdDir="$2"
  outputDir="$3"

  local filename
  filename=$(echo "${absoluteName}" | sed -e "s:${mdDir}/::" | sed -e "s:.md::")
  printf "filename:  %s\n" "${filename}"

  yarn mmdc -i "${mdDir}/${filename}.md" -o "${outputDir}/${filename}.svg"
}

mkdir -p "${OUTPUT}"

FILES=$(ls -1 "${MD_DIR}"/*.md)

for file in ${FILES}; do
  generate "${file}" "${MD_DIR}" "${OUTPUT}"
done
