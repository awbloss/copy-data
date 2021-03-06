
/****** Object:  UserDefinedFunction [dbo].[udf_CleanColumnName]    Script Date: 10/20/2016 6:50:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*  Created by Andrew Bloss 10/20/2016.

    This function turns camel cased column names and replaces non letters with short character strings.

    The following tables are used as input:

    select * from ColumnNameReplaceMap order by StringToReplace;

    Words in Acronym are capitalized as acronyms.

    Test with:
    select dbo.udf_CleanColumnName('A$')
    select dbo.udf_CleanColumnName('A$')

    select distinct ColumnName, dbo.udf_CleanColumnName(ColumnName)
    from DestinationColumnDefinition 
    order by ColumnName

*/

if object_id('udf_CleanColumnName') is not null 
drop function udf_CleanColumnName;
go

CREATE function [dbo].udf_CleanColumnName (@in varchar(4000))
RETURNS VARCHAR(4000)
AS
BEGIN

declare 
    @out varchar(4000) = '',
    @word varchar(4000) = '',
    @x int = 1,
    @a char = '';

set @in = replace(replace(@in, '[', ''), ']', '');

while @x <= len(@in)
begin

    set @a = substring(@in, @x, 1);

    -- Add word characters to @word.
    if @a like '[a-z]'
    begin
        set @word = @word + case when @word = '' then upper(@a)
                                 else @a
                             end;
    end;

    -- Output @word when you reach the end of the word or the end of the input. Capitalize acronymns.
    if @x = len(@in) or @a not like '[a-z]'
    begin 
        set @out = @out + case 
                              when @word in (select name from acronym) then upper(@word)
                              else @word
                          end;
        set @word = '';
    end;

    -- Add non-word characters to @word.
    if @a not like '[a-z]'
    begin
        set @out = @out + @a;
    end;

    set @x += 1;
end;


SELECT @out = REPLACE(REPLACE(REPLACE(@out, StringToReplace, ReplacementString), CHAR(13), ''), CHAR(10), '')
  FROM ColumnNameReplaceMap

-- Use the original case if nothing has changed.
IF LEN(@out) = LEN(@in) AND @out = @in 
SET @out = @in;

-- Capitalize id at the end of the input. Do not capitalize ID in Bid.
IF SUBSTRING(@out, LEN(@out) - 1, 2) = 'Id' 
    and SUBSTRING(@out, LEN(@out) - 2, 1) not in ('B')
begin 
    SET @out = STUFF(@out, (LEN(@out) - 1), 2, UPPER(SUBSTRING(@out, LEN(@out) - 1, 2)));
end;

SET @out = QUOTENAME(@out)

-- Replace 1St with 1st.
if charindex('1st ', @in) <> 0
set @out = replace(@out, '1St', '1st');

RETURN @out

END

