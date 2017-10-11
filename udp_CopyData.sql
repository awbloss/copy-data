use CopyData;
set ansi_nulls on;
set quoted_identifier on;
set nocount on;

if object_id('udp_CopyData', 'p') is not null
drop procedure udp_CopyData;
go

 /*
Author:  Andrew Bloss.
Created: 2016/12/1


**Action:** 

Copy SQL Server data from a source table to a destination table. Source and destination table may be in different schema, database and server. 

**Input:**

    @p_SourceTable              varchar(700),
    @p_DestinationTable         varchar(700),
    @p_SourceWhere              varchar(1000) = '1=1',
    @p_InsertIntoPrimaryKeyFlag int = 1,
    @p_PrintFlag                int = 1,
    @p_ExecuteFlag              int = 1
    
    
**Output:**

Select data in the source table and insert it into the destination table.

Comments preceding the insert show matched and unmatched source and destination column names and their datatypes. Columns are sorted by datatype to aid troubleshooting execution errors.

**Components:**

Function udf_CleanColumnName standardizes column name formatting and aids matching source and destination column names. 
Tables ColumnNameReplaceMap and Acronym and used by udf_CleanColumnName.
Table ColumnNameMatch matches columns in the source table to columns with different names in the destination table for when the name matching provided by udf_CleanColumnName is not sufficient. 
Table ColumnNameNoInsert keeps column names that should not be inserted into.  

**Execution**

udp_CopyData fills #SourceColumn and #DestinationColumn with the name and data type of the columns in @p_SourceTable and @p_DestinationTable. @Cursor is set to a cursor that contains a insert statement that inserts into the destination table data selected from the source table. @Cursor is passed to udp_Rev, which executes the statement in the cursor. The statement is preceded by a comment which shows how the statement was built.

 */
create procedure [dbo].[udp_CopyData]
    @p_SourceTable              varchar(700),
    @p_DestinationTable         varchar(700),
    @p_SourceWhere              varchar(max) = '1=1',
    @p_InsertIntoPrimaryKeyFlag int = 1,
    @p_PrintFlag                int = 1,
    @p_ExecuteFlag              int = 1
as
begin
    set nocount on;

    declare
        @SourceTable                varchar(700)    = @p_SourceTable,
        @DestinationTable           varchar(700)    = @p_DestinationTable,
        @SourceWhere                varchar(max)    = @p_SourceWhere,
        @InsertIntoPrimaryKeyFlag   int             = @p_InsertIntoPrimaryKeyFlag,
        @PrintFlag                  int             = @p_PrintFlag,
        @ExecuteFlag                int             = @p_ExecuteFlag,
        @SourceSchema               varchar(130)    = '',
        @SourceDatabase             varchar(130)    = '',
        @SourceServer               varchar(130)    = '',
        @DestinationSchema          varchar(130)    = '',
        @DestinationDatabase        varchar(130)    = '',
        @DestinationServer          varchar(130)    = '';
        
    declare
        @SourceFullName             varchar(700),
        @SourceInformationSchema    varchar(700),
        @DestinationFullName        varchar(700),
        @DestinationInformationSchema varchar(700),
        @SourceColumnSql            varchar(max) = '',
        @DestinationColumnSql       varchar(max) = '',
        @Cursor cursor;
    
    CREATE TABLE #SourceColumn (
        ColumnPosition int,
        ColumnName varchar(130),
        CleanColumnName varchar(130),
        ColumnDataType varchar(130)
    );

    CREATE TABLE #DestinationColumn (
        ColumnPosition int,
        ColumnName varchar(130),
        CleanColumnName varchar(130),
        ColumnDataType varchar(130),
        PrimaryKeyFlag int
    );

    CREATE TABLE #PrimaryKeyColumnsToExcludeFromInsert (
        ColumnName varchar(130),
    );

    CREATE TABLE #OtherColumnsToExcludeFromInsert (
        ColumnName varchar(130),
    );


    -- if @SourceTable contains ServerName.DatabaseName.SchemaName.TableName then separate them.
    if len(@SourceTable) - len(replace(@SourceTable, '.', '')) = 3
    begin
        set @SourceServer = substring(@SourceTable, 1, charindex('.', @SourceTable) - 1);
        set @SourceTable = substring(@SourceTable, charindex('.', @SourceTable) + 1, 700);
    end;
        
    -- if @SourceTable contains DatabaseName.SchemaName.TableName then separate them.
    if len(@SourceTable) - len(replace(@SourceTable, '.', '')) = 2
    begin
        set @SourceDatabase = substring(@SourceTable, 1, charindex('.', @SourceTable) - 1);
        set @SourceTable = substring(@SourceTable, charindex('.', @SourceTable) + 1, 700);
    end;
        
    -- if @SourceTable contains SchemaName.TableName then separate them.
    if len(@SourceTable) - len(replace(@SourceTable, '.', '')) = 1
    begin
        set @SourceSchema = substring(@SourceTable, 1, charindex('.', @SourceTable) - 1);
        set @SourceTable = substring(@SourceTable, charindex('.', @SourceTable) + 1, 700);
    end
    else set @SourceSchema = 'dbo';

    -- if @DestinationTable contains ServerName.DatabaseName.SchemaName.TableName then separate them.
    if len(@DestinationTable) - len(replace(@DestinationTable, '.', '')) = 3
    begin
        set @DestinationServer = substring(@DestinationTable, 1, charindex('.', @DestinationTable) - 1);
        set @DestinationTable = substring(@DestinationTable, charindex('.', @DestinationTable) + 1, 700);
    end;
        
    -- if @DestinationTable contains DatabaseName.SchemaName.TableName then separate them.
    if len(@DestinationTable) - len(replace(@DestinationTable, '.', '')) = 2
    begin
        set @DestinationDatabase = substring(@DestinationTable, 1, charindex('.', @DestinationTable) - 1);
        set @DestinationTable = substring(@DestinationTable, charindex('.', @DestinationTable) + 1, 700);
    end;
        
    -- if @DestinationTable contains SchemaName.TableName then separate them.
    if len(@DestinationTable) - len(replace(@DestinationTable, '.', '')) = 1
    begin
        set @DestinationSchema = substring(@DestinationTable, 1, charindex('.', @DestinationTable) - 1);
        set @DestinationTable = substring(@DestinationTable, charindex('.', @DestinationTable) + 1, 700);
    end
    else set @DestinationSchema = 'dbo';
        
        
    set @SourceTable        = coalesce(replace(replace(@SourceTable, '[', ''), ']', ''), '');
    set @SourceSchema       = coalesce(replace(replace(@SourceSchema, '[', ''), ']', ''), '');
    set @SourceDatabase     = coalesce(replace(replace(@SourceDatabase, '[', ''), ']', ''), '');
    set @SourceServer       = coalesce(replace(replace(@SourceServer, '[', ''), ']', ''), '');

    set @DestinationTable   = coalesce(replace(replace(@DestinationTable, '[', ''), ']', ''), '');
    set @DestinationSchema  = coalesce(replace(replace(@DestinationSchema, '[', ''), ']', ''), '');
    set @DestinationDatabase = coalesce(replace(replace(@DestinationDatabase, '[', ''), ']', ''), '');
    set @DestinationServer  = coalesce(replace(replace(@DestinationServer, '[', ''), ']', ''), '');

    set @SourceFullName = 
        case when @SourceServer <> ''   then '[' + @SourceServer + '].' else '' end + 
        case when @SourceDatabase <> '' then '[' + @SourceDatabase + '].' else '' end + 
        case when @SourceSchema <> ''   then '[' + @SourceSchema + '].' else '' end + 
        '[' + @SourceTable + ']';

    set @DestinationFullName = 
        case when @DestinationServer <> ''   then '[' + @DestinationServer + '].' else '' end + 
        case when @DestinationDatabase <> '' then '[' + @DestinationDatabase + '].' else '' end + 
        case when @DestinationSchema <> ''   then '[' + @DestinationSchema + '].' else '' end + 
        '[' + @DestinationTable + ']';

    set @SourceInformationSchema = 
        case when @SourceServer <> ''   then '[' + @SourceServer + '].' else '' end + 
        case when @SourceDatabase <> '' then '[' + @SourceDatabase + '].' else '' end + 
        '[INFORMATION_SCHEMA]';

    set @DestinationInformationSchema = 
        case when @DestinationServer <> ''   then '[' + @DestinationServer + '].' else '' end + 
        case when @DestinationDatabase <> '' then '[' + @DestinationDatabase + '].' else '' end + 
        '[INFORMATION_SCHEMA]';

    set @SourceColumnSql = 
    'select ordinal_position, '                                                                                                         + char(10) +
    'Column_Name, '                                                                                                                     + char(10) + 
    'dbo.udf_CleanColumnName(Column_name), '                                                                                            + char(10) + 
    'data_type + case when Data_Type like ''%char'' then ''('' + cast(character_maximum_length as varchar(20)) + '')'' else '''' end '  + char(10) + 
    'from ' + @SourceInformationSchema + '.Columns'                                                                                     + char(10) +
    'where table_name = ''' + @SourceTable + ''''                                                                                       + char(10) +
    'and table_schema = ''' + @SourceSchema + '''';

    insert into #SourceColumn(ColumnPosition, ColumnName, CleanColumnName, ColumnDataType)
    exec (@SourceColumnSql); 

    
    set @DestinationColumnSql = 
    'select c.ordinal_position, '                                                                                                               + char(10) +
    'c.Column_Name, '                                                                                                                           + char(10) + 
    'dbo.udf_CleanColumnName(c.Column_name), '                                                                                                  + char(10) + 
    'c.data_type + case when c.data_type like ''%char'' then ''('' + cast(c.character_maximum_length as varchar(20)) + '')'' else '''' end, '   + char(10) + 
    'case when pk.column_name is not null then 1 else 0 end '                                                                                   + char(10) +
    'from ' + @DestinationInformationSchema + '.Columns c '                                                                                     + char(10) + 
    'left join ('                                                                                                                               + char(10) +
        'select ku.table_catalog, ku.table_schema, ku.table_name, ku.column_name '                                                              + char(10) +
        'from ' + @DestinationInformationSchema + '.table_constraints as tc '                                                                   + char(10) +
        'join ' + @DestinationInformationSchema + '.key_column_usage as ku '                                                                    + char(10) +
        'on tc.constraint_type = ''PRIMARY KEY'' '                                                                                              + char(10) +
        'and tc.constraint_name = ku.constraint_name '                                                                                          + char(10) +
        'and tc.table_name = ''' + @DestinationTable + ''''                                                                                     + char(10) +
        'and tc.table_schema = ''' + @DestinationSchema + ''''                                                                                  + char(10) +
   ') as pk '                                                                                                                                   + char(10) + 
    'on c.table_catalog = pk.table_catalog '                                                                                                    + char(10) +
        'and c.table_schema = pk.table_schema '                                                                                                 + char(10) +
        'and c.table_name = pk.table_name '                                                                                                     + char(10) +
        'and c.column_name = pk.column_name '                                                                                                   + char(10) +
    'where c.table_name = ''' + @DestinationTable + ''''                                                                                        + char(10) +
    'and c.table_schema = ''' + @DestinationSchema + '''';


    insert into #DestinationColumn(ColumnPosition, ColumnName, CleanColumnName, ColumnDataType, PrimaryKeyFlag)
    exec (@DestinationColumnSql);

    -- Move primary key columns from #DestinationColumn to #PrimaryKeyColumnsToExcludeFromInsert.
    if @p_InsertIntoPrimaryKeyFlag = 0
    begin
        insert into #PrimaryKeyColumnsToExcludeFromInsert(ColumnName)
        select CleanColumnName
        from #DestinationColumn
        where PrimaryKeyFlag = 1;

        delete #DestinationColumn
        where PrimaryKeyFlag = 1;
    end;

    -- Move columns in ColumnNameNoInsert from #DestinationColumn to #OtherColumnsToExcludeFromInsert.
    insert into #OtherColumnsToExcludeFromInsert(ColumnName)
    select CleanColumnName
    from #DestinationColumn
    where CleanColumnName in (
        select dbo.udf_CleanColumnName(ColumnName)
        from ColumnNameNoInsert
    );

    delete #DestinationColumn
    where CleanColumnName in (
        select dbo.udf_CleanColumnName(ColumnName)
        from ColumnNameNoInsert
    );

    -- Insert data.    
    set @Cursor = cursor for
    with CleanSourceColumn as (
        select *
        from #SourceColumn 
    ) --select * from CleanSourceColumn order by 1,2; end;    
    ,
    CleanDestinationColumn as (
        select *
        from #DestinationColumn 
    ) --select * from CleanDestinationColumn order by 1,2; end;    
    ,
    CleanColumnNameMatch as (
        select 
            CleanSourceColumnName = dbo.udf_CleanColumnName(SourceColumnName),
            CleanDestinationColumnName = dbo.udf_CleanColumnName(DestinationColumnName)
        from ColumnNameMatch 
    ) --select * from CleanColumnNameMatch; end;
    ,
    MatchMaker as (
        Select 
            CleanSourceColumnName,
            CleanDestinationColumnName
        from CleanColumnNameMatch mtch
        join CleanSourceColumn src on mtch.CleanSourceColumnName = src.CleanColumnName
        join CleanDestinationColumn dst on mtch.CleanDestinationColumnName = dst.CleanColumnName

    ) --select * from MatchMaker; end; 
    ,
    DestinationColumnWithAlias as ( 
        select 
            dst.ColumnName,
            dst.CleanColumnName,
            ColumnAlias = coalesce(mtch.CleanSourceColumnName, dst.CleanColumnName),
            dst.ColumnDataType,
            IsAlias = case when mtch.CleanSourceColumnName is not null then 1 else 0 end
        from CleanDestinationColumn dst
        left outer join MatchMaker mtch on dst.CleanColumnName = mtch.CleanDestinationColumnName
    ) --select * from DestinationColumnWithAlias order by 1,2; end; 
    ,
    Columns as (
        select 
            SourceColumnName = src.ColumnName,
            SourceColumnDataType = src.ColumnDataType,
            DestinationColumnName = dst.ColumnName,
            DestinationColumnDataType = dst.ColumnDataType
        from DestinationColumnWithAlias dst
        join CleanSourceColumn src on dst.ColumnAlias = src.CleanColumnName
    ) -- select * from Columns; end; 
    select
    '/*-------------------------------------' + char(10) + 
    'Info for following insert.' + char(10) +
    (
        -- Parameter list.
        select 
            '@p_SourceTable = '             + coalesce(cast(@SourceTable as varchar(700)),'')               + ',' + char(10) + 
            '@p_DestinationTable = '        + coalesce(cast(@DestinationTable as varchar(700)),'')          + ',' + char(10) + 
            '@p_SourceWhere = '             + coalesce(cast(@SourceWhere as varchar(max)),'')               + ',' + char(10) + 
            '@p_InsertIntoPrimaryKeyFlag = ' + coalesce(cast(@InsertIntoPrimaryKeyFlag as varchar(5)),'')   + ',' + char(10) + 
            '@p_PrintFlag = '               + coalesce(cast(@PrintFlag as varchar(5)),'')                   + ',' + char(10) + 
            '@p_ExecuteFlag = '             + coalesce(cast(@ExecuteFlag as varchar(5)),'')                 + char(10) 
    ) + char(10) + 
    case when (select count(*) from #PrimaryKeyColumnsToExcludeFromInsert) > 0 then
        'Excluded from insert by being in destination PK (' + (
            select stuff((select ', ' + ColumnName 
            from #PrimaryKeyColumnsToExcludeFromInsert for xml path, type).value('.[1]','nvarchar(max)'),1,2,'')
        ) + ')' + char(10) + char(10) 
        else ''
    end +
    case when (select count(*) from #OtherColumnsToExcludeFromInsert) > 0 then
        'Excluded from insert by being in ColumnNameNoInsert (' + (
            select stuff((select ', ' + ColumnName 
            from #OtherColumnsToExcludeFromInsert for xml path, type).value('.[1]','nvarchar(max)'),1,2,'')
        ) + ')' + char(10) + char(10)
        else ''
    end +
    '* = matched by row in ColumnNameMatch.' + char(10) +
    'SourceDatatype DestinationDataType SourceColumnName [and DestinationColumnName if different]' +  char(10) +
    coalesce(
        (
            select 
                char(10) + 

                 --Print * if an ColumnNameMatch is used.
                 case when dst.IsAlias = 1 then '*' else '' end +   
                 coalesce(src.ColumnDataType,'null') + ' ' + 
                 case when dst.ColumnDataType is null then '' else dst.ColumnDataType + ' ' end + 
                 case when src.ColumnName is null then '' else src.ColumnName + ' ' end + 
                 case 
                     when coalesce(src.ColumnName, 'null') <> coalesce(dst.ColumnName,'null') 
                     then coalesce(dst.ColumnName,'null')
                     else ''
                end  
            from DestinationColumnWithAlias dst
            full outer join CleanSourceColumn src on 
                dst.ColumnAlias = src.CleanColumnName
            order by 
                -- List columns from the source that match columns in the destination, 
                -- then unmatched source columns, then unmatched destination columns.
                case 
                    when src.ColumnName is not null and dst.ColumnName is not null then 1 
                    when src.ColumnName is not null then 2 
                    else 3 
                end, 
                dst.ColumnDataType, src.ColumnDataType, src.ColumnName, dst.ColumnName
            for xml path('')
        )
    ,'NULL'
    ) + char(10) + 
    '*/' + char(10) + char(10) +
    coalesce(
        (
            'insert into ' + @DestinationFullName + '(' + char(10) +
            stuff((select ',' + DestinationColumnName + char(10)
                   from Columns  
                   order by DestinationColumnDataType, SourceColumnDataType, SourceColumnName, DestinationColumnName
                   for xml path(''))
                   ,1,1,''
            ) + 
            ')' + char(10) +
            'select ' + char(10) + 
            stuff((select ',' + SourceColumnName + char(10)
                   from Columns  
                   order by DestinationColumnDataType, SourceColumnDataType, SourceColumnName, DestinationColumnName
                   for xml path(''))
                   ,1,1,''
            ) +
            'from ' + @SourceFullName + char(10) + 
            'where ' + @SourceWhere
        ),
        'NULL'
    );

    exec udp_Rev @p_Cursor = @Cursor, @p_PrintFlag = @PrintFlag, @p_ExecuteFlag = @ExecuteFlag;
end;
go
