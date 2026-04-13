echo "Provide valid YouTube link: "
read -r link
yt-dlp -U --update-to nightly --abort-on-error --verbose $link
