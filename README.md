# In-Class 08 / Fall Festival Roster

## Student / Course / Pathway

-   **Student:** Samuel Raju Parisa
-   **Course:** Mobile Application Development
-   **Activity:** In-Class Activity 08 / Section 2 --- Local Storage:
    Make Data Stay
-   **Pathway:** Graduate
-   **Target platform:** Android
-   **Device:** V2312
-   **Device OS:** Android 15 (API 35)

## Flutter / Dart Versions and Setup

-   **Flutter:** 3.47.2, stable channel
-   **Dart:** 3.13.2
-   **DevTools:** 2.60.0
-   **IDE:** Visual Studio Code
-   **Android device:** V2312, Android 15 (API 35)

### Packages

Direct project dependencies observed from
`flutter pub deps --style=compact`:

-   `cupertino_icons 1.0.9`
-   `path 1.9.1`
-   `path_provider 2.1.6`
-   `sqflite 2.4.4+1`

### Setup / run commands

From the `local_storage_lab` project directory:

``` powershell
flutter pub get
flutter devices
flutter run
```

The app was run on the physical Android device `V2312`.

For static analysis:

``` powershell
flutter analyze
```

Observed result:

``` text
Analyzing local_storage_lab...
No issues found! (ran in 18.1s)
```

Saved at:

``` text
evidence/analysis_output.txt
```

## Storage Notes

### Schema and initialization

The app initializes a SQLite database named `MyDatabase.db`, version 1,
using `sqflite` and `path_provider`.

The table is:

``` text
my_table
```

with:

``` text
_id   INTEGER PRIMARY KEY
name  TEXT NOT NULL
age   INTEGER NOT NULL
```

The database is initialized once before the Flutter application is
launched. Records are inserted without manually supplying `_id`, so
SQLite generates the record IDs.

### Input policy, IDs, and CRUD

-   Guest names are trimmed and must not be blank or whitespace-only.
-   Ages are parsed with integer validation and must be between 0 and
    130 inclusive.
-   Decimal, non-numeric, negative, and greater-than-130 ages are
    rejected before a database write.
-   Generated integer IDs identify individual records.
-   Update and delete operations use the selected record ID and
    parameterized `whereArgs`.
-   Insert, query, update, and delete database operations are
    implemented in `lib/database_helper.dart`.
-   Form validation, record loading/counting, add/edit/delete UI
    behavior, and refresh behavior are implemented in `lib/main.dart`.

### Memory state example

The current text-field contents while the user is entering a guest are
in Flutter widget/controller state. For example, the name and age
currently typed into the form exist in the form controllers before the
user saves the record.

### Key-value preference example

A simple key-value preference that could be stored for this app would be
a setting such as:

``` text
preferred_theme = "dark"
```

The current lab does not require or use a key-value preferences store;
this is an example of the type of data that would fit that storage
approach.

### SQLite record example

A saved roster record is represented as a SQLite row such as:

``` text
_id = 2
name = "River"
age = 35
```

The final observed database also contained IDs 3 and 4 for Acorn and
Oak.

## Actual Tests

  ---------------------------------------------------------------------------
  Test           Action / input Expected       Observed IDs /  Pass/fail
                                               ages / count    
  -------------- -------------- -------------- --------------- --------------
  **T1**         Start with an  Count 0 and    `Records: 0`;   **PASS**
                 empty roster   empty-roster   "No festival    
                 and refresh    message        guests yet."    

  **T2**         Add River age  Two records    River 21 → **ID **PASS**
                 21 and River   with distinct  1**; River 34 → 
                 age 34         generated IDs  **ID 2**; count 
                                               **2**           

  **T3**         Edit River ID  Cancel changes Cancel left ID  **PASS**
                 2 from 34 to   nothing; saved 2 at **34**;    
                 99 and cancel; edit affects   final ID 2 =    
                 edit again and one row        **35**; count   
                 save as 35                    **2**           

  **T4**         Stop the app   Same records,  ID 1 = River    **PASS**
                 process and    IDs, ages, and 21; ID 2 =      
                 relaunch the   count survive  River 35; count 
                 same           restart        **2** after     
                 installation                  relaunch        
                 without                                       
                 clearing data                                 

  **T5**         Cancel a       Cancel         ID 1 removed;   **PASS**
                 delete, then   preserves      ID 2 = River    
                 confirm        record;        35; count **1** 
                 deletion of    confirmed                      
                 River ID 1 and delete removes                 
                 refresh        it                             

  **T6**         Test blank     Invalid values Invalid         **PASS**
                 name, `abc`,   rejected; 0    attempts left   
                 `1.5`, `-1`,   and 130        count **1**;    
                 `131`; then    accepted       Acorn ID 3 age  
                 test ages 0                   **0** and Oak   
                 and 130                       ID 4 age        
                                               **130**         
                                               accepted; final 
                                               count **3**     
  ---------------------------------------------------------------------------

### T6 invalid inputs

The following invalid cases were individually tested:

``` text
Name = spaces only, Age = 21
Name = Maple, Age = abc
Name = Maple, Age = 1.5
Name = Maple, Age = -1
Name = Maple, Age = 131
```

All were rejected and did not create database records.

Boundary cases:

``` text
Acorn, Age = 0  → accepted
Oak, Age = 130  → accepted
```

### Final observed roster

    ID Name      Age
  ---- ------- -----
     2 River      35
     3 Acorn       0
     4 Oak       130

**Final count: 3**

### T4 stop/relaunch method

For T4, the Flutter app process was stopped from the terminal, while the
Android application remained installed and its data was not cleared. The
app was then relaunched with:

``` powershell
flutter run
```

The same SQLite records and generated IDs were present after relaunch.

### Evidence

Required evidence files:

``` text
evidence/T4_before.png
evidence/T4_after.png
evidence/T6_invalid.png
evidence/analysis_output.txt
```

Additional T1, T2, T3, or T5 screenshots may be included if available.

### Analyzer result

Command:

``` powershell
flutter analyze
```

Result:

``` text
No issues found! (ran in 18.1s)
```

### Known limitations

-   The supplied SQLite setup is intended for Android/iOS, not Flutter
    Web or Windows/Linux desktop.
-   The app is intentionally a single-screen roster for this activity.
-   The lab does not implement cloud synchronization or recovery beyond
    the local SQLite database.
-   A fresh installation creates a fresh database; the submitted project
    should not contain a populated personal database.

## Short Reflections

### 1. Prediction before T4, then actual result / interpretation

**Prediction:** I expected the two River records to remain after
stopping and relaunching the app because they had been written to SQLite
rather than existing only in the form/widget state.

**Actual result:** After the real stop and relaunch, ID 1 remained River
age 21 and ID 2 remained River age 35, with a count of 2. This confirmed
that the saved SQLite records persisted independently of the running
Flutter process.

### 2. My two IDs and update result; why identity matters

The two River records initially received generated IDs **1** and **2**.
I cancelled an attempted edit of ID 2, which left its age at 34, and
then updated ID 2 successfully from 34 to 35.

Record identity matters because names are not guaranteed to be unique:
both records were named River. Using the generated ID makes it possible
to update or delete the intended row without confusing one River record
with the other.

### 3. Self-walkthrough observation and proposed improvement

Walking through the complete add, edit, cancel, delete, refresh,
validation, and restart workflow showed that the main screen gives
immediate feedback through the record count and roster list. The
persistence test was especially useful because it demonstrated that the
visible records were coming back from SQLite rather than merely
remaining in memory.

One improvement would be to make the validation/error feedback even more
explicit and consistent for every invalid input, while keeping the
current simple single-screen design.

### 4. Graduate only: validation / schema design reasoning

The table uses `NOT NULL` for `name` and `age`, but the schema alone
does not enforce the application's age range. For example, an integer
value such as `131` satisfies `INTEGER NOT NULL`, so the
application-level validator is necessary to enforce the business rule
that ages must be 0 through 130.

If the `CREATE TABLE` statement were changed for an already-existing
version-1 database without increasing the database version or adding an
upgrade migration, the existing database would not be recreated
automatically. The existing schema would remain in place because the
creation callback applies when the database is first created.

A data-preserving migration would increase the database version and
implement `onUpgrade`. The migration would alter or recreate the
affected structure while copying existing valid rows into the new
structure, preserving IDs and data where possible. The migration should
be tested with both a fresh database and an existing populated database.

## Attribution

### Starter source / own additions

The activity supplied the SQLite setup requirements, package versions,
database schema/interface expectations, test cases, and validation
requirements.

The project implementation follows those requirements. The database
helper in `lib/database_helper.dart` implements the required database
initialization and CRUD operations. The application-specific UI, form
handling, validation, record counting/listing, edit/delete workflow,
confirmation behavior, refresh behavior, and error handling are
implemented in `lib/main.dart`.

### Resources

-   Flutter documentation was used for Flutter/device troubleshooting
    and running the application on Android.
-   Android documentation was used for Android device/ADB setup.

### AI assistance

AI assistance was used to interpret the activity instructions,
troubleshoot the Flutter/Android environment, review the SQLite/Flutter
implementation, and organize the README and evidence documentation.

The application was manually run and tested on the physical Android
device documented above. The T1--T6 results in this README are based on
the observed application behavior.

## Submission Checklist

Before creating the ZIP:

-   [ ] `README.md` is present.
-   [ ] `lib/main.dart` is present.
-   [ ] `lib/database_helper.dart` is present.
-   [ ] `pubspec.yaml` and `pubspec.lock` are present.
-   [ ] `analysis_options.yaml` is present.
-   [ ] `android/` is included.
-   [ ] `ios/` is included.
-   [ ] `evidence/T4_before.png` is present.
-   [ ] `evidence/T4_after.png` is present.
-   [ ] `evidence/T6_invalid.png` is present.
-   [ ] `evidence/analysis_output.txt` is present.
-   [ ] `build/` is excluded.
-   [ ] `.dart_tool/` is excluded.
-   [ ] No populated personal database, signing keys, credentials, or
    machine-specific configuration is included.

The final archive should be named:

``` text
Parisa_Samuel_InClass08.zip
```
