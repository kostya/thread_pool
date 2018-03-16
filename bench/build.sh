for ex in $(find . | grep \\.cr)
do
  name="bin_$(echo $ex | tr \/\. '_')"
  echo "crystal build $ex -o $name --release"
  crystal build $ex -o $name --release
done
