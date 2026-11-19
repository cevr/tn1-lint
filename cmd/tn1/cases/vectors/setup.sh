root=$1
while [ ! -f "$root/ergo.mod" ]; do root=$(dirname "$root"); done
cp -R "$root/tn1/testdata/vectors" .
