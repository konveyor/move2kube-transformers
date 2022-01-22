#!/usr/bin/env bash

#   Copyright IBM Corporation 2022
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

repo='move2kube-transformers'
unset dir
zip_flag='false'

print_usage() {
  printf "Usage: ./download.sh -d <dir> -r <repo>"
  printf "use -z if output is required as zip"
}

while getopts 'r:d:z' flag; do
  case "${flag}" in
    a) repo="${OPTARG}" ;;
    b) dir="${OPTARG}" ;;
    f) zip_flag='true' ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ -z "$dir" ] then
    curl -Lo ${REPO_NAME}.zip https://github.com/konveyor/${REPO_NAME}/archive/refs/heads/main.zip 
    unzip ${REPO_NAME}.zip "${REPO_NAME}-main/*"
    mv "${REPO_NAME}-main/" "${REPO_NAME}"
    rm -rf ${REPO_NAME}.zip
    rm -rf "${REPO_NAME}-main"
    if [[ zip_flag = 'true' ]] then 
        zip -r ${REPO_NAME}.zip ${REPO_NAME}/
        rm -rf "${REPO_NAME}"
    fi
else
    base_dir=${dir##*/}
    curl -Lo ${REPO_NAME}.zip https://github.com/konveyor/${REPO_NAME}/archive/refs/heads/main.zip 
    unzip ${REPO_NAME}.zip "${REPO_NAME}-main/$dir/*"
    mv "${REPO_NAME}-main/$dir" "${base_dir}"
    rm -rf ${REPO_NAME}.zip
    rm -rf "${REPO_NAME}-main"
    if [[ zip_flag = 'true' ]] then 
        zip -r ${base_dir}.zip ${base_dir}/
        rm -rf "${base_dir}"
    fi
fi
