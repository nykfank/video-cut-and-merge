re_encoding <- TRUE
nb_seconds <- 5

merged_filename <- sprintf("jahresfilm_%s.mp4", gsub("[^0-9]", "", getwd()))
if (file.exists(merged_filename)) unlink(merged_filename)
filme <- sort(list.files(".", pattern="mp4"))

# Determine video resolutionution and FPS
fps <- c()
resolution <- c()
sampling_rate <- c()
for (f in filme) {
	cmd <- sprintf('mediainfo --Inform="Video;%%FrameRate%%" %s 2>&1', f)
	rf <- system(cmd, intern=TRUE)
	fps <- c(fps, as.numeric(rf))
	cmd <- sprintf('mediainfo --Inform="Video;%%Width%%" %s 2>&1', f)
	rw <- system(cmd, intern=TRUE)
	cmd <- sprintf('mediainfo --Inform="Video;%%Height%%" %s 2>&1', f)
	rh <- system(cmd, intern=TRUE)
	resolution <- c(resolution, sprintf("%s:%s", rw, rh))
	cmd <- sprintf('mediainfo --Inform="Audio;%%SamplingRate%%" %s 2>&1', f)
	rs <- system(cmd, intern=TRUE)
	sampling_rate <- c(sampling_rate, as.numeric(rs))
}

# Determine most frequent video FPS
fpst <- as.data.frame(table(fps), stringsAsFactors=FALSE)
fpst <- fpst[order(fpst$Freq, decreasing=TRUE),]
print(fpst, row.names=FALSE)
writeLines("")
top_fps <- round(as.numeric(fpst[1, "fps"]))

# Determine most frequent video resolution
resolutiont <- as.data.frame(table(resolution), stringsAsFactors=FALSE)
resolutiont <- resolutiont[order(resolutiont$Freq, decreasing=TRUE),]
print(resolutiont, row.names=FALSE)
writeLines("")
top_resolution <- resolutiont[1, "resolution"]

# Determine most frequent audio sampling rate
sampling_ratet <- as.data.frame(table(sampling_rate), stringsAsFactors=FALSE)
sampling_ratet <- sampling_ratet[order(sampling_ratet$Freq, decreasing=TRUE),]
print(sampling_ratet, row.names=FALSE)
writeLines("")
top_sampling_rate <- as.numeric(sampling_ratet[1, "sampling_rate"])

# Read shift and long text files
if (file.exists("shift.txt")) shift <- read.table("shift.txt", stringsAsFactors=FALSE)$V1 else shift <- NA
if (file.exists("long.txt")) lange <- read.table("long.txt", stringsAsFactors=FALSE)$V1 else lange <- NA
if (!dir.exists("cut")) dir.create("cut")

# Extract part from videos
for (f in filme) {
	outfile <- sprintf("cut/%s", f)
	if (file.exists(outfile)) next
	start <- sum(f == shift, na.rm=TRUE) * nb_seconds
	dauer <- nb_seconds + sum(f == lange, na.rm=TRUE) * nb_seconds
	writeLines(sprintf("%d/%d: %s %d to %d seconds", which(f == filme), length(filme), f, start, start+dauer))
	if (re_encoding == TRUE) {
		cmd <- sprintf("ffmpeg -hide_banner -loglevel panic -y -ss %d -i %s -t %d -vf scale=%s -codec:a aac -b:a 128k -ar %d -af aresample=async=1000 -codec:v libx264 -crf 20 -profile:v main -r %d -avoid_negative_ts make_zero -fflags +genpts %s", 
			start, f, dauer, top_resolution, top_sampling_rate, top_fps, outfile)
	} else {
		cmd <- sprintf("ffmpeg -hide_banner -y -ss %d -i %s -t %d -c copy %s", start, f, dauer, outfile)	
	}
	system(cmd)
}

# Merge parts of videoss
mergefiles <- sprintf("file '%s/cut/%s'", getwd(), filme)
tempTextFile <- sprintf("/tmp/vidfiles%d.txt", as.integer(Sys.time()))
write(mergefiles, file=tempTextFile)
cmd <- sprintf('ffmpeg -hide_banner -loglevel panic -y -f concat -safe 0 -i %s -c copy %s', tempTextFile, merged_filename)
writeLines(cmd)
system(cmd)
