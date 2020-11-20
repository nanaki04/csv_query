# CsvEditor

Commandline tool to query and edit csv files.

## Installation

Required erlang installed to run.

Clone this repository. In the root of the repository you will find the executable 'csvq'.
To have the command available globally, copy the executable to an executable location, or add a path to your environment.

ex:
```
cp csvq /usr/local/bin/csvq
```

## Usage

Either go to the folder containing the csv files you wish to edit and run the executable without arguments, or run the executable from anywhere with the folder name containing the csv files you wish to edit as only argument.

```
$ cd /folder/with/csv/files
$ csvq
```

```
$ csvq /folder/with/csv/files
```

### Available queries:

```
> ls
```
List all loaded csv files.

```
> ls {pattern}
```
List all loaded csv files that match the given pattern.

```
> desc {table}
```
Display all headers of the given table.
That table name corresponds to the csv file name minus '.csv'.

```
> select {header1 header2...} from {table} where {header = value header2 = value2...}
```
Select query to display a tables content.
When no headers to select are given, all headers will be shown.
When no where clauses are present, all records will be listed.

```
> update {table} where {header = value header2 = value2...} set {header = new_value header2 = new_value2...}
```
Update query to set one or more values to one or more records.
When no where clauses are present, all records in the table will be updated.

```
> copy {option} from {table} where {header = value header2 = value2...} to {index}
```
Copy the first record matching the where clause, to the given index.
If no index is given, the copy will be appended to the end of the table.
If 'prepend' is given as option, the copy will be prepended at the start of the table instead.

```
> save
```
Save all changes made to all loaded csv files.

```
> quit
```
alias: q  
Quit the cli.
