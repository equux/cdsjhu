run_analysis.R:

This script processes data from the "Human Activity Recognition Using Smartphones" data set, which was collected from 30
subjects performing a wide variety of daily activities while wearing smartphones with inertial sensors.

An abstract of this experiment and the resulting data set may be found here: http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

The script itself endeavors to create a tidy data set along the lines prescribed by Wickham (each variable is a column, each
observation is a row, etc.). It reads in a set of training and test observation data distributed across a number of flat files, as
well as some metadata about the features themselves, and performs the following operations:
* Feature names are normalized -- readability is improved, mistakes are corrected, extraneous punctuation is removed.
* Test and training data is aggregated into a single observation set, then restricted to the features we are concerned with
  for this project (means and standard deviations).
* A narrow, tall data table is created that has a row for each feature in each observation for each subject and activity.
* Finally, all of that data is summarized by taking the mean of each feature for each subject/activity pair and recording
  that in a row with the subject and activity pair. This yields 180 rows in total (30 subjects * 6 activities), and the new,
  tidied data set is written to disk.