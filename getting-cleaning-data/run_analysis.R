# run_analysis.R : A description of this program's function is in the Readme.MD file found with this distribution.
# To use this program successfully, you will need to do the following:
# 1. Ensure that the data.table and reshape2 R packages are installed on your local system
# 2. Download the sample smartphone data from https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip
#    and unzip it into a directory of your choice.
# 3. Edit the setwd() line below to reflect the proper path to the top level directory of the unzipped smartphone data.

# Load required packages
require("data.table")
require("reshape2")

# Set our local working directory to the top-level directory of the raw smartphone data.
setwd("~/coursera-get-clean-data/UCI HAR Dataset")

# Read the raw training data into data frames in R
# trainobs will contain all of the measurement data from "X_train.txt"
# trainsubj will contain the subject associated with each observation in the above set. We'll set its column name to "subject."
# trainactivity will contain the activity ID associated with each observation. We'll set its column name to "activity."

trainobs <- read.table("train/X_train.txt")
trainsubj <- read.table("train/subject_train.txt")
names(trainsubj) <- c("subject")
trainactivity <- read.table("train/y_train.txt")
names(trainactivity) <- c("activity")

# Read the raw test data into data frames in R
# testobs will contain all of the measurement data from "X_test.txt"
# testsubj will contain the subject associated with each observation in the above set. We'll set its column name to "subject."
# testactivity will contain the activity ID associated with each observation. We'll set its column name to "activity."

testobs <- read.table("test/X_test.txt")
testsubj <- read.table("test/subject_test.txt")
names(testsubj) <- c("subject")
testactivity <- read.table("test/y_test.txt")
names(testactivity) <- c("activity")

# Activity_labels.txt contains key, value pairs of activity ID and human-readable Activity Name. We'll set the column names
# to activity for the ID (to match the name chosen for the test/training versions) and activityName for the Activity Name

activities <- read.table("activity_labels.txt")
names(activities) <- c("activity", "activityName")

# Features.txt contains the name of each feature captured in the *obs data frames above in the second field. Since we don't
# need the index value in the first field, we will throw it away at read time.
features <- read.table("features.txt")[,2]

# The feature names are fairly messy. This series of substitutions cleans them up as follows:
# * lowercase t at the start of a feature name or after a parenthesis is expanded to "time" for readability
# * lowercase f at the start of a feature name is expanded to "frequency" for readability
# * double parentheses () are removed whenever they appear
# * numbers separated by hyphens have the hyphen replaced by the word "to", e.g.: 1-5 becomes 1to5
# * left parentheses are removed -- any lowercase letter appearing in the next position is made uppercase for readability
# * remaining hyphens are removed -- any lowercase letters are handled as above
# * commas are removed -- any lowercase letters are handled as above
# * multiple occurrences of the word "Body" are replaced by a single one
# * remaining right parentheses are removed.

features <- gsub("^t", "time", features)
features <- gsub("\\(t","Time", features)
features <- gsub("^f", "frequency", features)
features <- gsub("\\(\\)", "", features)
features <- gsub("(\\d+),(\\d+)", "\\1to\\2", features)
features <- gsub("\\((\\w)", "\\U\\1", features, perl=TRUE)
features <- gsub("-(\\w)", "\\U\\1", features, perl=TRUE)
features <- gsub(",(\\w)", "\\U\\1", features, perl=TRUE)
features <- gsub("(Body)+", "\\1", features)
features <- gsub("\\)", "", features)

# Finally, we assign the cleaned feature names to the columns of the test and training observation data frames.
names(testobs) <- features
names(trainobs) <- features

# Now, we narrow the list of features to those indicating standard deviations and means of given measurements, as this
# was a requirement of the assignment. I have chosen to leave out the "MeanFreq" and angular measurements.
featuresOnlyMeanAndStd <- features[(grepl("[Ss]td", features) | grepl("[Mm]ean", features)) & 
                                     !grepl("^angle", features) & !grepl("[Mm]ean[Ff]req", features)]

# We build a data table as follows that aggregates most of what we loaded from the files on disk:
# 1. We column bind the training observations (but only the columns containing the features we want)
#    with the training subject and training activity data.
# 2. We column bind the test data (observations, subject, activity) in the same way.
# 3. We row bind the two data frames above and use setDT() to create a data table for faster processing later.
#
# The final result is a data table containing all the features we wanted as well as subject and activity ID data
# for both the training and test sets.
aggregateData <- setDT(rbind(cbind(trainobs[ ,featuresOnlyMeanAndStd],trainsubj,trainactivity),
                       cbind(testobs[, featuresOnlyMeanAndStd],testsubj, testactivity)))

# We now merge this data table with the activities data frame we loaded previously, "joining" on the activity column.
# This adds the activityName to each row of our data table.
aggregateData <- merge(aggregateData, activities, by="activity")

# Once we have the activityName, we can throw away the activity ID by removing the activity column.
aggregateData[, activity:=NULL]

# Now, we use the melt function to yield a 4 column table with subject, activityName, variable, and value. This creates a
# very tall table as each feature measured as part of a given observation is now in its own row.
tallData <- melt(aggregateData, c("subject", "activityName"))

# Finally, we use dcast to summarize the data, taking the average of the values of each feature variable by subject and activity 
summaryData <- dcast(tallData, subject + activityName ~ variable, mean)

# ...and write out the tidier data to disk, suppressing the row names
write.table(summaryData, "tidy-smartphone-data.txt", row.names = FALSE)
