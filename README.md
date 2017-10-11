# udp_CopyData

Procedure udp_CopyData is for ad-hoc copying of SQL data from one table to another. The source and destination tables can be in different servers, databases, and schemas. 

udp_CopyData builds an insert statement that selects data from a source table and inserts it into a destination table. The insert statement is built in a SQL cursor and passed to procedure udp_Rev for execution and printing. This centralizes error handling and logging of execution and errors, which aids maintenance. A large comment preceding the insert statement shows matched and unmatched source and destination column names and their datatypes. The columns in the comment are sorted by datatype to aid troubleshooting execution errors caused by values that would be truncated or can not be converted to the destination column type. 

The set based declaritive code in udp_CopyData helps in development, testing, and debugging, as does printing comprehensive comments about the columns and the column name matches.

**udp_CopyData Parameters**

    @p_SourceTable varchar(700),
    @p_DestinationTable varchar(700),
    @p_SourceWhere varchar(1000) = '1=1',
    @p_InsertIntoPrimaryKeyFlag int = 1,
    @p_PrintFlag int = 1,
    @p_ExecuteFlag int = 1
	
@p_SourceTable is the table to select rows from. It may include a linked server, database, and schema.<br/>
@p_DestinationTable is the table to insert rows into. It may include a linked server, database, and schema.<br/>
@p_SourceWhere is a where clause for the select.<br/>
@p_InsertIntoPrimaryKeyFlag controls whether the primary key columns of the destination table are included in the columns that have values inserted.<br/>
@p_PrintFlag and @p_ExecuteFlag control whether the contents of the cursor are printed and/or executed.<br/>

**udf_CleanColumnName**<br/>
In addition to procedure udp_CopyData and udp_Rev, function udf_CleanColumnName helps match source table column names to destination column names by standardizing formatting. 

**Setup Tables**<br/>
**ColumnNameNoInsert** holds a list of destination columns that are not to be inserted into. This is useful for column names that have defaults.

**ColumnNameMatch** matches columns in the source table to columns with different names in the destination table when the name matching provided by udf_CleanColumnName is not enough.

**ColumnNameReplaceMap** and **Acronym** are used by function udf_CleanColumnName. The ColumnNameReplaceMap table holds pairs of strings, a string to find and a string to replace the found string. The Acronym table holds acronyms that should be capitalized. 
