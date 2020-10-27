# ReadFileFromContents
Create SAS read-in statements using proc contents output read from a lst file

## What this does
This code will allow you to use proc contents output to generate SAS statements to read in a CSV file that was exported from the dataset described in the contents output.

## Why I did it
Often we receive data in CSV format because SAS files are too large for efficient transfer.  In these cases a contents output is delivered along with the CSV file.  

PROC IMPORT has many short-comings including automatic naming and formatting of variables.  For longer CSV files this often results in the truncation of longer variables or in odd naming conventions or nonsensical labeling of variables.  Rather than fight with the various features of proc import, I wanted to read my data in exactly as expected based on the contents provided to me along with the data.

## How to use the code
The main program used here is read_contents_output.sas.
* The program crates a macro called read_contents
* The comments within the code will tell you how to set up the macro variables in your macro call.
* There is an example macro call at the bottom of the page that I used to demonstrate how the macro works.  There is no data or CSV file included in the repo. 
* The SAS program that is created by the example macro call is sas_readins.sas.  It is in the repo to show you what you can expect but it doesn't have any other function.
