merged_filename <- sprintf("jahresfilm_%s.mp4", gsub("[^0-9]", "", getwd()))
re_encoding <- TRUE
writeLines(sprintf("Output: %s", merged_filename))
if (file.exists(merged_filename)) unlink(merged_filename)
filme <- list.files(".", pattern="mp4")
fps <- c()
resol <- c()
for (f in filme) {
	cmd <- sprintf('mediainfo --Inform="Video;%%FrameRate%%" %s 2>&1', f)
	rf <- system(cmd, intern=TRUE)
	fps <- c(fps, round(as.numeric(rf)))
	cmd <- sprintf('mediainfo --Inform="Video;%%Width%%" %s 2>&1', f)
	rw <- system(cmd, intern=TRUE)
	cmd <- sprintf('mediainfo --Inform="Video;%%Height%%" %s 2>&1', f)
	rh <- system(cmd, intern=TRUE)
	resol <- c(resol, sprintf("%s:%s", rw, rh))

}
fpst <- as.data.frame(table(fps), stringsAsFactors=FALSE)
fpst <- fpst[order(fpst$Freq, decreasing=TRUE),]
print(fpst, row.names=FALSE)
top_fps <- as.numeric(fpst[1, "fps"])
resolt <- as.data.frame(table(resol), stringsAsFactors=FALSE)
resolt <- resolt[order(resolt$Freq, decreasing=TRUE),]
print(resolt, row.names=FALSE)
top_resol <- resolt[1, "resol"]
if (file.exists("s")) shift <- read.table("s", stringsAsFactors=FALSE)$V1 else shift <- NA
if (file.exists("l")) lange <- read.table("l", stringsAsFactors=FALSE)$V1 else lange <- NA
if (!dir.exists("cut")) dir.create("cut")
for (f in filme) {
	outfile <- sprintf("cut/%s", f)
	start <- sum(f == shift) * 5
	dauer <- 5 + sum(f == lange) * 5
	if (re_encoding == TRUE) {
		cmd <- sprintf("ffmpeg -hide_banner -loglevel panic -y -ss %d -i %s -t %d -vf scale=%s -codec:v libx264 -crf 18 -profile:v main -r %d %s", start, f, dauer, top_resol, top_fps, outfile)
	} else {
		cmd <- sprintf("ffmpeg -hide_banner -y -ss %d -i %s -t %d -c copy -r 30 %s", start, f, dauer, outfile)	
	}
	writeLines(cmd)
	system(cmd)
}

mergefiles <- sprintf("file '%s/cut/%s'", getwd(), filme)
tempTextFile <- sprintf("/tmp/vidfiles%d.txt", as.integer(Sys.time()))
write(mergefiles, file=tempTextFile)
cmd <- sprintf('ffmpeg -hide_banner  -loglevel panic -y -f concat -safe 0 -i %s -c copy %s', tempTextFile, merged_filename)
writeLines(cmd)
system(cmd)
