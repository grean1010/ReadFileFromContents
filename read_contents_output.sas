****************************************************************;
** Title:   read_contents_output.sas                          **;
** Author:  Maria Cupples Hudson                              **;
** Date:    May 2020                                          **;
** Purpose: Creates a macro that will read in proc contents   **;
**          output and create SAS read-in statements.         **;
****************************************************************;
options symbolgen;

%let test_folder = C:\Users\mhudson\OneDrive - Mathematica\Documents\marias_projects\cool sas stuff\contents_reader;
libname test "&test_folder";

%let outfile_loc = C:\Users\mhudson\OneDrive - Mathematica\Documents\marias_projects\cool sas stuff\contents_reader;


* This macro will read any lst file and create SAS steps to read in;
* datasets based on the contents in that lst file.;

* INPUTS TO THE MACRO:                                                   ;
* fileref      = The full path a file name of the lst file to be read.   ;
* dlmloc       = The location of the delimited files we eventually read  ;
* dlmext       = The file extension of delimited files we eventually read;
*                OPTIONAL-- Defaults to txt                              ;
* dlm          = The delimeter in that file (comma, pipe, tab)           ;
*                VALUES:  |, pipe, %str(,), comma, tab, '09'x            ;
*                OPTIONAL-- Defaults to | (pipe)                         ;
* firstlinedlm = The first line to read in of the delimited file.        ;
*                OPTIONAL-- Defaults to 1.                               ;
* outloc       = The location of the SAS file to be created.             ;
* outtxt       = The name (name.sas) of the SAS file to be created.      ;
%macro read_contents(cfile=,dlmloc=,dlmext=txt,dlm=|,firstlinedlm=1,outloc=,outtxt=);

  filename cfile "&cfile";

  data temp_readin;
    length line remaining_line $500. test_fmt test_ifmt $1.
           library_name dsname varname $75. vnum 8. type $5. len 8.
           fmt ifmt $75. lbl $256. vnum_char $10.
           nvars nvars_found 8.
           has_fmt has_ifmt has_lbl 8.
           fmt_start ifmt_start lbl_start 8.
           within_contents_output within_var_lines 8.;
    infile cfile truncover expandtabs;
    input line $500.;

    * Retain the dataset information throughout the data step.;
    * Update each time we come to a new proc contents output;
    retain library_name dsname nvars nvars_found   
           has_fmt has_ifmt has_lbl 
           fmt_start ifmt_start lbl_start
           within_contents_output within_var_lines;

    * Look for the phrase THE CONTENTS PROCEDURE to indicate the beginning;
    * of a proc contents output within a lst file. Set flags to indicate that;
    * we are within a proc contents output and that we have not yet reached;
    * the variable output lines.;
    if index(upcase(line),'THE CONTENTS PROCEDURE') > 0 then do;
      within_contents_output = 1;
      within_var_lines = 0;
    end;

    * The beginning of each proc contents output, before the variable output;
    * lines, we need to pull the dataset name and number of variables.;
    if within_contents_output = 1 and within_var_lines = 0 and
       index(upcase(line),'DATA SET NAME') = 1 then do;

      * Reset dataset-specific variables;
      library_name = ''; dsname = ''; nvars = .; nvars_found = 0;
      has_fmt = 0; has_ifmt = 0; has_lbl = 0; 
      fmt_start = 0; ifmt_start = 0; lbl_start = 0;

      * The dataset name comes after the text DATA SET NAME. ;
      * Take everything remaining in the line. Remove spaces.;
      dsname = left(trim(substr(line,14)));

      * If there is a DOT in the dataset name then it has both libname and a datasetname.;
      * Substring the libname into the variable library_name. Keep the rest as the dataset name.;
      if index(dsname,'.') > 0 then do;
        library_name = substr(dsname,1,index(dsname,'.')-1);
        dsname = substr(dsname,index(dsname,'.')+1);
        dsname = left(trim(substr(dsname,1,index(dsname,' '))));
      end;

      * If there is no DOT then the library is the work directory;
      else library_name = "WORK";

    end;

    * The number of variables in the dataset is stored on the line that starts with member type;
    if within_contents_output = 1 and within_var_lines = 0 and
       index(upcase(line),'MEMBER TYPE') = 1 and index(upcase(line),'VARIABLES') > 0 then do;

      * Pull text that occurs after the phrase VARIABLES and convert to numeric;
      nvars = input(left(compress(substr(line,index(upcase(line),'VARIABLES')+9))),8.);

    end;

    * The phrase ALPHABETIC LIST OF VARIABLES AND ATTRIBUTES signals the ;
    * beginning of the variable output.  Reset the flag accordingly.;
    if index(upcase(line),'ALPHABETIC LIST OF VARIABLES AND ATTRIBUTES') > 0 then
      within_var_lines = 1;

    * The variable description line tells which attributes of each variable will be;
    * printed out. Variable name, type, and lentgh always come first. Format, informat;
    * and label are only printed if they appear for one or more variables in the dataset;
    if within_var_lines = 1 and index(upcase(line),'VARIABLE')>0 and
       index(upcase(line),'TYPE')>0 and index(upcase(line),'LEN')>0 then do;

      if index(upcase(line),'INFORMAT') > 0 then has_ifmt = 1;
      if index(upcase(line),'LABEL') > 0 then has_lbl = 1;

      * If we do not have an informat, then look for the word FORMAT to determine if there is a format;
      * If there is an informat, look for FORMAT to come before INFORMAT to determine if there is a format;
      if has_ifmt = 0 and index(upcase(line),'FORMAT') > 0 then has_fmt = 1;
      else if has_ifmt = 1 and index(upcase(line),'FORMAT') < index(upcase(line),'INFORMAT') then has_fmt = 1;
      else has_fmt = 0;

      * Pull the starting position for the format, iformat, and label.  Set to zero if they are not present.;
      if has_ifmt = 1 then ifmt_start = index(upcase(line),'INFORMAT');
      if has_fmt = 1 then fmt_start = index(upcase(line),'FORMAT');
      if has_lbl = 1 then lbl_start = index(upcase(line),'LABEL');

    end;

    if within_var_lines = 1 and substr(left(trim(line)),1,1) in ('1','2','3','4','5','6','7','8','9','0')
       and compress(line) ne '' then do;

      * Increment the count of the number of variables we have found;
      nvars_found = sum(nvars_found,1);

      * Pull the variable number from the input line.;
      vnum_char = left(trim(substr(line,1,index(line,' '))));
      vnum = input(vnum_char,8.);

      * If the variable number is between less than 10, we pull test characters for format and iformat ;
      * from the starts determined above.  If the variable number is between 10 and 99, we need to add ;
      * one to the starting points. If it is between 100 and 999, we add 2.  Etc.                      ;
      if has_fmt then test_fmt = substr(line,fmt_start + length(vnum_char) - 1,1);
      if has_ifmt then test_ifmt = substr(line,ifmt_start + length(vnum_char) - 1,1);

      * Drop the variable number from the line read in. We do not need this.;
      remaining_line = left(trim(substr(line,index(line,' '))));

      * Pull variable information. The substring out the variable name into the remaining line variable.;
      varname = left(trim(substr(remaining_line,1,index(remaining_line,' '))));
      remaining_line = left(trim(substr(remaining_line,index(remaining_line,' '))));

      * Pull type from the remaining line. The substring out the type from the remaining line.;
      type = left(trim(substr(remaining_line,1,index(remaining_line,' '))));
      remaining_line = left(trim(substr(remaining_line,index(remaining_line,' '))));

      * Pull the length from the remaining line. Substring out as before.;
      len = left(trim(substr(remaining_line,1,index(remaining_line,' '))));
      remaining_line = left(trim(substr(remaining_line,index(remaining_line,' '))));

      * If the proc contents has a column for format then we check the column position;
      * in the original line to see if this variable has a format. If so, pull that value;
      * from the remaining line and subset it out;
      if has_fmt = 1 and test_fmt ne '' then do;
        fmt = left(trim(substr(remaining_line,1,index(remaining_line,' '))));
        remaining_line = left(trim(substr(remaining_line,index(remaining_line,' '))));
      end;

      * If there is an informat, take it from the remaining line and substring out.;
      if has_ifmt and test_ifmt ne '' then do;
        ifmt = left(trim(substr(remaining_line,1,index(remaining_line,' '))));
        remaining_line = left(trim(substr(remaining_line,index(remaining_line,' '))));
      end;

      * If there is not a specified informat then we create one from the variable;
      * type and length. We need this for the input statement. ;
      else do;
        if upcase(type)="CHAR" then ifmt = "$"||compress(put(len,8.))||".";
        else ifmt = compress(put(len,8.))||".";
        ifmt = left(compress(ifmt));
      end;

      * A this point, the only thing left in the remaining line is the label (if any);
      if has_lbl then lbl = left(trim(remaining_line));

      * If this is the last variable then reset the flags;
      if nvars_found = nvars then do;
        within_var_lines = 0;
        within_contents_output = 0;
        nvars_found = 0;
      end;

      * We only keep the variable lines in the output dataset;
      output;

    end; 

    keep varname library_name dsname fmt ifmt type lbl vnum nvars len
         has_fmt has_ifmt has_lbl;

  run;

  * Sort by the variable number so we can create SAS read-in statements;
  proc sort data=temp_readin;
    by library_name dsname vnum;
  run;

  * Create the read-in statements;
  data read_stmts;
    set temp_readin;
    by library_name dsname;

    length stmt $300. qdlm $7.;

    * comma or pipe-delimiters need to have single quotes around them for the input statement;
    qdlm = left(trim("&dlm"));
    qdlm = left(trim(qdlm));
    if upcase(qdlm) in (",","COMMA","C") then qdlm = "','";
    if upcase(qdlm) in ("|","PIPE","P") then qdlm = "'|'";
    if upcase(qdlm) in ("'09'X",'"09X"',"TAB","T") then qdlm = "'09'x";

    if first.dsname then do;
      stmt = "data " || left(trim(dsname)) || ";";
      output ;
      stmt = "infile '" || "&dlmloc.\"|| left(trim(dsname)) ||".&dlmext'";
      output;
      stmt = "dlm=" || left(trim(qdlm)) || " dsd truncover";
      output ;
      stmt = "firstobs=&firstlinedlm;";
      output;
    end;
    
	keep library_name dsname qdlm stmt;
  run;

  data len_stmts;
    set temp_readin;
    by library_name dsname;

    length stmt $300. ;

    if first.dsname then do;
	  stmt = "length ";
      output ;
    end;

    * Output each variable name followed by the length.;
    if upcase(type)="CHAR" then stmt = left(trim(varname))||" $"||compress(put(len,8.))||".";
    else stmt = left(trim(varname))||" "||compress(put(len,8.))||".";

    * At the last variable for this dataset, close the input statement;
    if last.dsname then stmt = trim(stmt)||";";
    output;
    
  	keep library_name dsname stmt;
  run;

  data input_stmts;
    set temp_readin;
    by library_name dsname;

	  length stmt $300. qdlm $7.;

    if first.dsname then do;
	  stmt = "input ";
      output ;
    end;

    * Output each variable name followed by the informat.;
    *stmt = "        " || left(trim(varname)) || " :" || left(trim(ifmt)) ;
    stmt = left(trim(varname));

    * At the last variable for this dataset, close the input statement;
    if last.dsname then stmt = trim(stmt)||";";
    output;
    
	  keep library_name dsname qdlm stmt;
  run;


  * Variable Format statements;
  data fmt_stmts;
    set temp_readin;
    by library_name dsname;

    length stmt $300. ;

    if fmt ne '' then do;
      stmt = "format " || left(trim(varname)) || " " || left(trim(fmt)) || ";";
      output;
    end;
    keep library_name dsname stmt;
  run;


  * Variable label statements;
  data lbl_stmts;
    set temp_readin;
    by library_name dsname;

    length stmt $300. ;

    if lbl ne '' then do;
      stmt = "label "|| left(trim(varname)) || ' = "' || left(trim(lbl)) || '";';
      output;
    end;
    if last.dsname then do;
      stmt = "run;";
      output;
    end;
    keep library_name dsname stmt;
  run;

  data all_stmts;
    set read_stmts (in=a) len_stmts (in=b) input_stmts (in=c)
        fmt_stmts  (in=d) lbl_stmts (in=e);
    linenum = _n_;
    if a then sortorder = 1;
    else if b then sortorder = 2;
    else if c then sortorder = 3;
    else if d then sortorder = 4;
    else if e then sortorder = 5;
  run;

  proc sort data=all_stmts;
    by library_name dsname sortorder linenum;
  run;

  data _null_;
    set all_stmts;
    by library_name dsname sortorder linenum;
    file "&outloc.\&outtxt";
    if first.sortorder then put ;
    if substr(stmt,1,4) in ('data','run;') then put stmt;
    else if sortorder = 1 then do;
      if substr(stmt,1,4) = 'infi' then put @2 stmt;
      else put @5 stmt;
    end;
    else if sortorder = 2 then do;
      if first.sortorder then put @2 stmt;
      else put @10 stmt;
    end;
    else if sortorder = 3 then do;
      if first.sortorder then put @2 stmt;
      else put @9 stmt;
    end;
    else put @ 2 stmt;
  run; 
/*
  proc datasets lib=work nolist;
    delete temp_readin read_stmts fmt_stmts lbl_stmts;
    quit;
  run;
*/
%mend read_contents;
%read_contents(cfile=&test_folder\test_contents.lst,
               dlmloc=N:\Project\50887_MedicaidAccess\DC1\Task 5\Report 2 (Refresh)\5. Programs,
               dlmext=csv,
               dlm=comma,
               firstlinedlm=2,
               outloc=&test_folder,
               outtxt=sas_readins.sas);