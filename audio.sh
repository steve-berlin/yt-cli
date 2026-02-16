echo "Link: "
read -r link
yt-dlp --list-formats $link
echo "Choose an available audio format: "
read -r format
echo "Choose path (default is ~/Music): "
if [ $path=="" ]; then
  $path="~/Music"
fi
yt-dlp -U --update-to nightly --abort-on-error --verbose -x -f "ba[ext=$format]" $link -P "$path"
