-- ffmpegSplitter.applescript
-- ffmpegSplitter

--  Created by Patrick on 20.04.09.
--  Copyright 2009 Patrick Mosby. All rights reserved.

property outputFolder : (path to movies folder from user domain as Unicode text)
property extension_list : {"flv", "avi", "mp4", "mov", "wmv", "divx", "h264", "mkv", "m4v"}
property filePath : ""
property newFilePath : ""
property startTimeCode : ""
property durationTimeCode : ""
property ffmpegpid : ""
property ASTID : ""
property ffmpegRunning : true
property bitrate : ""

on idle
	(* Add any idle time processing here. *)
end idle

on clicked theObject
	if name of theObject is "cancelButton" then
		try
			do shell script "kill -9 " & ffmpegpid
		end try
		
		try
			do shell script "rm " & newFilePath
		on error
			display dialog "Could not delete the file"
		end try
		
		close window "ProgressWindow"
		display dialog "Process canceled" buttons {"OK"} giving up after 5
		quit
	else if name of theObject is "inputButton" then
		set newFileName to choose file name with prompt ¬
			"Please provide a name for the newly created movie:" default name ¬
			"SplitVideo.mp4" default location (outputFolder as alias)
	else if name of theObject is "outputButton" then
		set newFileName to choose file name with prompt ¬
			"Save extracted video as:" default name ¬
			"SplitVideo.mp4" default location (outputFolder as alias)
		set newFilePath to quoted form of POSIX path of newFileName
		set the contents of text field "outputField" of window "MainWindow" to newFilePath as text
	end if
end clicked

on startProgress()
	show window "ProgressWindow"
	start progress indicator "ProgressIndicator" of window "ProgressWindow"
end startProgress

on endProgress()
	set ffmpegRunning to process_running("ffmpeg")
	
	repeat while ffmpegRunning
		set ffmpegRunning to process_running("ffmpeg")
	end repeat
	
	stop progress indicator "ProgressIndicator" of window "ProgressWindow"
	display dialog "Process finished" buttons {"OK"} giving up after 5
	close window "ProgressWindow"
end endProgress

on process_running(process_name)
	return (do shell script "ps axc") contains process_name
end process_running

on processFile()
	try
		-- set ffmpegSplitterBundle_Path to call method "bundlePath" of object main bundle -- (*Work out where the app is located.*)
		startProgress()
		
		if startTimeCode is equal to "00:00:00" and durationTimeCode is equal to "00:00:00" then
			-- just convert the file
			do shell script "/usr/local/bin/ffmpeg -i " & filePath & ¬
				" -acodec libfaac -ab 128k -vcodec libx264 -b 1000k -threads 2 -subq 4 " & ¬
				" " & newFilePath & "&> /dev/null & echo $!"
			set ffmpegpid to the result
		else if startTimeCode is not equal to "00:00:00" and durationTimeCode is equal to "00:00:00" then
			-- convert from startTimeCode to end of file
			do shell script "/usr/local/bin/ffmpeg -i " & filePath & ¬
				" -acodec libfaac -ab 128k -vcodec libx264 -b 1000k -threads 2 -subq 4 -ss " & ¬
				startTimeCode & " " & newFilePath & "&> /dev/null & echo $!"
			set ffmpegpid to the result
		else if startTimeCode is not equal to "00:00:00" and durationTimeCode is not equal to "00:00:00" then
			-- convert from startTimeCode to durationTimeCode
			do shell script "/usr/local/bin/ffmpeg -i " & filePath & ¬
				" -acodec libfaac -ab 128k -vcodec libx264 -b 1000k -threads 2 -subq 4 -ss " & ¬
				startTimeCode & "-t " & durationTimeCode & " " & newFilePath & "&> /dev/null & echo $!"
			set ffmpegpid to the result
		else
			-- convert from start of file to durationTimeCode
			do shell script "/usr/local/bin/ffmpeg -i " & filePath & ¬
				" -acodec libfaac -ab 128k -vcodec libx264 -b 1000k -threads 2 -subq 4 -t " & ¬
				durationTimeCode & " " & newFilePath & "&> /dev/null & echo $!"
			set ffmpegpid to the result
		end if
		
		endProgress()
	on error errMsg number errNum
		set AppleScript's text item delimiters to ASTID
		display dialog "Error (" & errNum & "):" & return & return & errMsg buttons "Cancel" default button 1 with icon caution
	end try
end processFile

on open names
	set ASTID to AppleScript's text item delimiters
	set AppleScript's text item delimiters to {"."}
	
	set fileToSplit to first item of names
	set theFileInfo to info for fileToSplit
	
	if the name extension of the theFileInfo is not in the extension_list then
		display dialog "Sorry but your file does not appear to be a video" & return & return & ¬
			"This dialog will close in 3 seconds" with icon 0 ¬
			buttons {"OK"} ¬
			giving up after 3
		-- quit
	else
		set filePath to quoted form of POSIX path of fileToSplit
		set the contents of text field "inputField" of window "MainWindow" to filePath as text
		
		-- show window "MainWindow"
	end if
end open