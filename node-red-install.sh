#!/bin/sh

# Check if USB Storage is Presesnt
	# Return USB Device Path 

# Check device size
	# Check if the space is sufficient

# Check if internet is connected
	# Ping something 
	# Return true or false

# Download Node Red to USB Storage(Path to USB)

# Create Soft Link

# Use opkg to install node-red console app

getFileSize () {
	URL="http://repo.onion.io/omega2/software/node-red.tar.gz"
	resp=$(wget --spider $URL 2>&1 | grep Length | awk '{print $2}')
	ans=$(expr $resp / 1024)
	echo $ans
}

getUsbSize (){
	path=$1
	#Available space
	size=$(df $1 | sed -n 2p | awk '{print $4}')
	echo $size
}

isUsbFound(){
	dirList=$(ls /tmp/run/mountd/)
	fileSize=$(getFileSize)
	if [ "$dirList" == "" ]; then
		#No Usbs found
		echo '0'
	else
		for word in $dirList
		do
			path="/tmp/run/mountd/$word"
			usbSize=$(getUsbSize $path)
			if [ "$usbSize" -gt "$fileSize" ]; then
				# Sends the path back
				echo $path
				return
			else
				continue
			fi
		done
		# Return 1 to show that not enough space on usbs
		echo '1'
	fi
}

isOnline (){
check=$(ping -q -w 1 -c 1 `ip r | grep default | cut -d ' ' -f 3` > /dev/null && echo ok || echo error)
if [ "$check" == "ok" ]; then
	echo '1'
else
	echo '0'
fi
}

downloadNode(){
	usbPath=$1
	#Download
	output=$(wget -O $usbPath/node-red.tar.gz http://repo.onion.io/omega2/software/node-red.tar.gz)
	#Extract
	unzip=$(tar -xvzf $usbPath/node-red.tar.gz -C $usbPath/)
	echo $unzip
}

createExec(){
	usbPath=$1
	echo $usbPath
	echo "#!/bin/sh" > /usr/bin/node-red
	echo "node $usbPath/node-red/red.js" >> /usr/bin/node-red
	chmod +x /usr/bin/node-red
}

main(){
	onlineCheck=$(isOnline)
	if [ "$onlineCheck" == "0" ]; then
		exit
	fi
	# Device is online
	path=$(isUsbFound)
	if [ "$path" == "0" ]; then
		# No usbs found
		exit
	fi
	if [ "$path" == "1" ]; then
		# Not enough space on usbs
		exit
	fi
	# Found a usb with enough space
	downloadNode $path
	createExec $path
}
main