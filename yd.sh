#!/bin/bash

# Function to download best preMerged video
function downloadVid1(){
	yt-dlp -N 10 --no-playlist -f "(webm,mp4)[height<=$resolution]" -o "%(title)s.%(ext)s" "$link"

	# Comment for pre-merged video downlaod
	commentType1 $filename
}

# Function to download Unmerged video, audio if available, otherwise download best merged format available.
function downloadVid2(){
	# Non pre-merged download high bitrate download, heigher bitrate mean larger file size, and better quality.
	# Video Bit rate 5775k is premium in id 616 and cause error while merging, need to filter id 616, also filtering vbr.
	# Note: Unable to downlaod video resolution heigher than 1440p, because of filter, need to find another way
	# Note: id filter is useless.
	# yt-dlp -N 10 --no-playlist -f "bestvideo[height<=$resolution][id!=616]+bestaudio/bestvideo[height<=$resolution][vbr<5700]+bestaudio/best[height<=$resolution]" -o "%(title)s.%(ext)s" "$link"

	# Going to use / to skip currently known  premium
	# for known resolution donwload either higher vbr, or lower vbr than premium vbr
	# for 616: 1080, vbr = 5775


	# new logic
	# Check if file already exist
	# if file exit, comment
	# if file doesn't exit, download . Note: Note: not download && comment, because comment will execute even if download was terminate.
	# after download statement, again check if file exist, if it exist, then comment.

	export filename=$(yt-dlp -N 10 --no-playlist -f "bestvideo[height<=$resolution][vbr>5800]+bestaudio/bestvideo[height<=$resolution][vbr<5700]+bestaudio/best[height<=$resolution]" --get-filename -o "%(title)s.%(ext)s" "$link")
	if [ -e "$filename" ]; then
		# Comment for already downloaded video file
		commentType1 
	else
		echo "downloading $filename"
		yt-dlp -N 10 --no-playlist -f "bestvideo[height<=$resolution][vbr>5800]+bestaudio/bestvideo[height<=$resolution][vbr<5700]+bestaudio/best[height<=$resolution]" -o "%(title)s.%(ext)s" "$link"
		if [ -e "$filename" ]; then
			# Comment for already downloaded video file
			commentType1
		fi
	fi

}

# Function to comment after downloading pre merged video

###
function commentType1()
{
	sed -i "s|$link|# &\t# $filename|g" "$LinkFile"
# # 		# In the sed substitution command, & represents the entire matched pattern. In this case $link
}

# #old code for test
# function commentType1()
# {
# # 	#sed -i "s|$link|# $link\t#Downloaded: $video_file|" "$LinkFile"
# # 		# the above one was generating repeatin links in the comments.
# # 
# # 	# echo -e "$link\\t# $video_file" | sed "s|$link|&|"
# # 		# for testing
# # 
# 	sed -i "s|$link|# &\t# $video_file|g" "$LinkFile"
# # 		# Now working as inteded
# # 		# In the sed substitution command, & represents the entire matched pattern.
# }

# Function to manually merge video and audio files 
	# Args: video_file audio_file output_file
	# Deletes the original video_file and audio_file

###
function merge_video_audio(){
	# Local Parameters, Function Parameters initialization.
	local video_file="$1"
	local audio_file="$2"
	local output_file="$3"

	# Use ffmpeg to the video and audio files into a new output file.
	ffmpeg -i "$video_file" -i "$audio_file" -c:v copy -c:a aac -strict experimental "$output_file" >/dev/null 2>&1
		#>/dev/null 2>&1: Redirects both standard output and standard error to /dev/null, effectively suppressing FFmpeg's output.

	# Remove the original video and audio files after merging
	rm "$video_file" "$audio_file"
}



# Function to check if LinkFile is provided as an argument
    # Call the function with the script's command-line arguments
    #check_arguments "$@"
	#"$@" represents all the arguments passed to the script). This way, it checks if the LinkFile argument is provided when the script is executed.

###
function check_arguments() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 LinkFileName"
        exit 1
    fi
}


# Function to get video resolution info for downloading.
	# Get resolution info and store in resolution variable.
	# Requires a global "resolution" string type variable before call
	# It may automatically create one if not declared.

###
function getResolutionInfo(){
	local
	# Prompt for video resolution	
		# -z is a test for an empty string, i.e. while resolution variable contains an emptly string
	while [ -z "$resolution" ]; do
		echo "Select video resolution:"
		echo "1. 4320p (8K)"
		echo "2. 2160p (4K)"
		echo "3. 1440p (2K)"
		echo "4. 1080p (Full HD)"
		echo "5. 720p (HD)"
		echo "6. 480p"
		echo "7. 360p"
		echo "8. 240p"
		echo "9. 144p"
		echo "10. Audio Only (Highest Quality)"
		
		## Read user choice for resolution
		read -r choice
		## Assign the choice (if proper value for choice) value to resolution variable
		case "$choice" in
		1)
			resolution="4320"
			;;
		2)
			resolution="2160"
			;;
		3)
			resolution="1440"
			;;
		4)
			resolution="1080"
			;;
		5)
			resolution="720"
			;;
		6)
			resolution="480"
			;;
		7)
			resolution="360"
			;;
		8)
			resolution="240"
			;;
		9)
			resolution="144"
			;;
		10)
			resolution="audio"
			;;
		*)
			echo "Invalid choice. Try again."
			;;
		esac
	done

}

# Function to read all the links from the input LinkFile and store them in an array name links.
	# reads the links from the $LinkFile
	# stores all the lines in $links[]

###
function getLinks(){
	# Read all the links from the LinkFile and store them in an array
	readarray -t links <"$LinkFile"
}

# Function to traverse the links array and process each link 
	## Requires links array to created

###
function processLinks(){
	# Traverse the links array and process each link	
	for link in "${links[@]}"; do
		# Skip if the line is empty or starts with a comment (#)
		if [[ -z "$link" || "$link" == \#* ]]; then
			continue
		fi
		
		
		# Check if the file is already downloaded in the current directory
			# If file exist do not download again and continue.
			# If already downloaded:
				# Comment out the by prefixing it with "#"
				# Add "# Already Downloaded" at the end the link followed by a whitespace.
		# Download video and audio separately or combined as per preference 
		echo "Downloading Link: $link"
		# video_file=$(yt-dlp -f "bestvideo[height<=$resolution]" --get-filename -o "%(title)s.%(ext)s" "$link")
			# now handled in downloadVid function

			# Download audio only with the best quality available. 
			# Download video and audio with the selected resolution.

		# Download premerged video and audio with the selected resolution
		# echo "Downloading Pre-merged video"
		# echo "Downloading Video\n"
		# echo "Downloading $video_file"
			# now handled in downloadVid function
		downloadVid2

		# Prompt if downlaod fails
		
	# For manually merging downlaoded video and audio
		# Find downloaded audio file
		# Find downloaded video and audio files
		# Merge video and audio:
		# Generate the output merged file name
	###	# Call the function to merge merge video and audio files
		# Comment out the original link and add the merged file name as a comment followed by a space at the end of the link.


		# Comment out the link if it's an audio-only download

		# Comment for invalid urls.
		# Check if urls are available for downlaoding.
		found_urls=true
	done
	
}

# function to Prompt if no urls available

###
function urlAvailability(){
	if ! "$found_urls"; then
		echo "No URLs available for downlaoding."
	fi
}

## ##
## ##
## ##
## ##

# Check if LinkFile is provided as an agrument.
check_arguments "$@"

# Declare/Initialise global variables
LinkFile="$1"
resolution=""
found_urls=false


# Prompt for video resolution
getResolutionInfo

# Read all the links from the LinkFile and store them in an array named links
getLinks

# Traverse the links array and process each link.
processLinks

# Check if any URLs were found or not
urlAvailability

