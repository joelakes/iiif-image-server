#!/bin/sh

set -e  # exit on script error

# Run from project root
test ! -d scripts && echo "scripts dir not found in $PWD, exiting..." && exit 1

echo "# Testing identifier resolution"

echo "## objectstore resolution"
./config/delegates_test.rb objectstore:beeldbank-B00000026214.jpg "https://f8d5776e78674418b6f9a605807e069a.objectstore.eu/Images/beeldbank-B00000026214.jpg"
echo ""

 echo "## edepot resolution"
 ./config/delegates_test.rb 'edepot:SA-00702-SA00632608_00001.jpg' "https://bwt.uitplaatsing.hcp-a.basis.lan/rest/SA/00702/SA00632608_00001.jpg"
 echo ""

 echo "## wabo resolution"
 ./config/delegates_test.rb 'wabo:SDC-DOCUMENTUM-PRIMARY-27-0901B69980392066.PDF' "http://127.0.0.1:50000/webDAV/SDC/DOCUMENTUM/PRIMARY/27/0901B69980392066.PDF"
 echo ""

 echo "## beeldbank resolution"
 ./config/delegates_test.rb beeldbank:B00000030938 "https://beeldbank.amsterdam.nl/component/ams_memorixbeeld_download/?format=download&id=B00000030938"
 echo ""

 echo "## filesystem resolution"
 export USE_LOCAL_SOURCE=true
 ./config/delegates_test.rb fs:test.jpg "/images/fs:test.jpg"
 echo ""
