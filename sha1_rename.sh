#!/usr/bin/env bash
# rename all the files under current folder to {sha1:8}.ext
#
# ln -s ~/git/stainboy.github.io/sha1_rename.sh /usr/bin/sm
# cd ~/git/stainboy.github.io/assets/cloud/2015
# sm

git_root=$(git rev-parse --show-toplevel)
trim_size=`expr ${#git_root} + 2`
prefix=$(echo $PWD | cut -c $trim_size-)

for of in $(find -type f)
do
    sha1=$(sha1sum $of | awk '{print $1}' | cut -c -8)
    if [ ! "./$sha1" = "${of%.*}" ]; then
        nf=$sha1.${of##*.}
        echo "rename $of to $nf"
        mv $of $nf
        echo "  ![$sha1]({{ site.BASE_PATH }}/$prefix/$nf)"
    fi
done