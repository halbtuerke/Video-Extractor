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
		end try
		
		quit
	else if name of theObject is "inputButton" then
		set fileName to choose file with prompt ¬
			"Please choose a movie file:" default location (outputFolder as alias) without invisibles
		set theFileInfo to info for fileName
		
		-- refactor this
		if the name extension of the theFileInfo is not in the extension_list then
			display dialog "Sorry but your file does not appear to be a video" & return & return & ¬
				"This dialog will close in 3 seconds" with icon 0 ¬
				buttons {"OK"} ¬
				giving up after 3
		else
			set filePath to quoted form of POSIX path of fileName
			set the contents of text field "inputField" of window "MainWindow" to filePath as text
		end if
	else if name of theObject is "outputButton" then
		set newFileName to choose file name with prompt ¬
			"Save extracted video as:" default name ¬
			"SplitVideo.mp4" default location (outputFolder as alias)
		set newFilePath to quoted form of POSIX path of newFileName
		set the contents of text field "outputField" of window "MainWindow" to newFilePath as text
	else if name of theObject is "startButton" then
		setBitrate()
		setStartTimeCode()
		setDurationTimeCode()
		
		log "bitrate: " & bitrate
		log "filePath: " & filePath
		log "newFilePath: " & newFilePath
		log "startTimeCode: " & startTimeCode
		log "durationTimeCode: " & durationTimeCode
		
		processFile()
	end if
end clicked

on setBitrate()
	if state of button "losslessCheckButton" of window "MainWindow" is 1 then
		set bitrate to "-sameq"
	else
		set bitrate to "-b 1000k"
	end if
end setBitrate

on setStartTimeCode()
	set startTemp to the contents of text field "startTimeField" of window "MainWindow" as text
	if startTemp is equal to "HH:MM:SS" then
		set startTimeCode to "00:00:00"
	else
		set startTimeCode to startTemp
	end if
end setStartTimeCode

on setDurationTimeCode()
	set durationTemp to the contents of text field "durationTimeField" of window "MainWindow" as text
	if durationTemp is equal to "HH:MM:SS" then
		set durationTimeCode to "00:00:00"
	else
		set durationTimeCode to durationTemp
	end if
end setDurationTimeCode

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
		set videoExtractorBundle_Path to call method "bundlePath" of object main bundle
		set ffmpegBinary to videoExtractorBundle_Path & "/Contents/Resources/ffmpeg"
		set ffmpegBinaryPath to quoted form of POSIX path of ffmpegBinary
		
		startProgress()
		
		log ffmpegBinaryPath
		log bitrate
		log startTimeCode
		log durationTimeCode
		log filePath
		log newFilePath
		
		if startTimeCode is equal to "00:00:00" and durationTimeCode is equal to "00:00:00" then
			-- just convert the file
			do shell script ffmpegBinaryPath & " -i " & filePath & ¬
				" -acodec libfaac -ab 128k -vcodec libx264 " & bitrate & " -threads 2 -subq 4 " & ¬
				newFilePath & " &> /dev/null & echo $!"
			set ffmpegpid to the result
			log ffmpegpid
		else if startTimeCode is not equal to "00:00:00" and durationTimeCode is equal to "00:00:00" then
			-- convert from startTimeCode to end of file
			do shell script ffmpegBinaryPath & " -i " & filePath & ¬
				" -acodec libfaac -ab 128k -vcodec libx264 " & bitrate & " -threads 2 -subq 4 -ss " & ¬
				startTimeCode & " " & newFilePath & " &> /dev/null & echo $!"
			set ffmpegpid to the result
			log ffmpegpid
		else if startTimeCode is not equal to "00:00:00" and durationTimeCode is not equal to "00:00:00" then
			-- convert from startTimeCode to durationTimeCode
			do shell script ffmpegBinaryPath & " -i " & filePath & ¬
				" -acodec libfaac -ab 128k -vcodec libx264 " & bitrate & " -threads 2 -subq 4 -ss " & ¬
				startTimeCode & " -t " & durationTimeCode & " " & newFilePath & " &> /dev/null & echo $!"
			set ffmpegpid to the result
			log ffmpegpid
		else
			-- convert from start of file to durationTimeCode
			do shell script ffmpegBinaryPath & " -i " & filePath & ¬
				" -acodec libfaac -ab 128k -vcodec libx264 " & bitrate & " -threads 2 -subq 4 -t " & ¬
				durationTimeCode & " " & newFilePath & " &> /dev/null & echo $!"
			set ffmpegpid to the result
			log ffmpegpid
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