# Online Evaluation of Courses (OEC) Support tasks

## Configuration

* Settings.oec has the list of terms and departments to restrict the export.
* Make sure your campusdb points at production oracle (bspprod) and that you have access to it.

## Rake tasks

* `rake oec:courses`
    1. This will generate a courses-{timestamp}.csv in tmp/oec.
    2. Send that file to Daphne.
    3. Daphne will filter out unwanted courses and give you back the filtered CSV.
    4. Copy the filtered CSV to tmp/oec/courses.csv

* `rake oec:instructors`
    1. This will generate 2 new CSV files in tmp/oec: One for instructors, and one for instructors' relationships to courses, all based on the CCNs found in courses.csv from the previous step.

* `rake oec:students`
    1. This will generate 2 new CSV files in tmp/oec: One for students, and one for students' relationships to courses, all based on the CCNs found in courses.csv from the previous step.

## Weekly Update

* Log in to prod-03 and become app_calcentral user

* Update code:
```
cd ~/oec-export
git pull
bundle install
```

* Generate courses file:
```
RAILS_ENV=production rake oec:courses
cp tmp/oec/courses-{timestamp}.csv tmp/oec/courses.csv
```

* Now securely transfer courses.csv and attach to JIRA
* Justin will modify courses.csv and attach updated file to JIRA
* Then overwrite tmp/oec/courses.csv with the version from Justin

* Generating instructor files (only if Justin doesn't want to use his manually-curated ones):
```
RAILS_ENV=production rake oec:instructors
cp tmp/oec/instructors-{timestamp}.csv tmp/oec/instructors.csv
cp tmp/oec/course_instructors-{timestamp}.csv tmp/oec/course_instructors.csv
```

* Generating student files
```
RAILS_ENV=production rake oec:students
cp tmp/oec/students-{timestamp}.csv tmp/oec/students.csv
cp tmp/oec/course_students-{timestamp}.csv tmp/oec/course_students.csv
```
