use CopyData;

Set nocount on;
--Test ColumnNameNoMatch and @p_PrimaryKeyColumnNoInsert together.
print 'Make code work for schemas and add test.'
-----------------------------------------------
Print 'Test Matching Column Names.'

delete ColumnNameNoInsert;

if object_id('a') is not null drop table a;
if object_id('b') is not null drop table b;
go

Create table a(a int, b int, c int);
Create table b(a int , b int,  c int);

insert into a(a, b, c)
values (1, 2, 3);

delete b;

exec udp_CopyData 
    @p_SourceTable = 'a',
    @p_DestinationTable = 'b',
    --@p_SourceDatabase varchar(130) = null,
    --@p_SourceServer varchar(130) = null,
    --@p_SourceWhere varchar(1000) = '1=1',
    --@p_DestinationDatabase varchar(130) = null,
    --@p_DestinationServer varchar(130) = null,
    @p_InsertIntoPrimaryKeyFlag = 1,
    @p_PrintFlag = 1,
    @p_ExecuteFlag = 1;

if exists(select a, b, c from a
except
select a, b, c from b)
print 'Failed Matching Column Names.'
else 
print 'Passed Matching Column Names.';


print ''
print ''
print 'Test Unmatched Column In Source.'
alter table a add d int;
delete b;
exec udp_CopyData 
    @p_SourceTable = 'a',
    @p_DestinationTable = 'b',
    --@p_SourceDatabase varchar(130) = null,
    --@p_SourceServer varchar(130) = null,
    --@p_SourceWhere varchar(1000) = '1=1',
    --@p_DestinationDatabase varchar(130) = null,
    --@p_DestinationServer varchar(130) = null,
    @p_InsertIntoPrimaryKeyFlag = 1,
    @p_PrintFlag = 1,
    @p_ExecuteFlag = 1

if exists(select a, b, c from a
except
select a, b, c from b)
print 'Failed Unmatched Column In Source.'
else 
print 'Passed Unmatched Column In Source.';


print ''
print ''
Print 'Test Unnmatched Column in Destination.'
alter table b add e int;
delete b;

exec udp_CopyData 
    @p_SourceTable = 'a',
    @p_DestinationTable = 'b',
    --@p_SourceDatabase varchar(130) = null,
    --@p_SourceServer varchar(130) = null,
    --@p_SourceWhere varchar(1000) = '1=1',
    --@p_DestinationDatabase varchar(130) = null,
    --@p_DestinationServer varchar(130) = null,
    @p_InsertIntoPrimaryKeyFlag = 1,
    @p_PrintFlag = 1,
    @p_ExecuteFlag = 1

if exists(
select a, b, c from a
except
select a, b, c from b)
print 'Failed Unnmatched Column in Destination.'
else 
print 'Passed Unnmatched Column in Destination.';


print ''
print ''
Print 'Test Error because of insert into Identity.'
if object_id('a') is not null drop table a;
if object_id('b') is not null drop table b;
go

delete ColumnNameNoInsert;

Create table a(rowid int identity primary key, a int, b int, c int);
Create table b(rowid int identity primary key, a int , b int,  c int);

insert into a(a, b, c)
values (1, 2, 3);

begin try
	exec udp_CopyData 
		@p_SourceTable = 'a',
		@p_DestinationTable = 'b',
		--@p_SourceDatabase varchar(130) = null,
		--@p_SourceServer varchar(130) = null,
		--@p_SourceWhere varchar(1000) = '1=1',
		--@p_DestinationDatabase varchar(130) = null,
		--@p_DestinationServer varchar(130) = null,
		@p_InsertIntoPrimaryKeyFlag = 1,
		@p_PrintFlag = 1,
		@p_ExecuteFlag = 1;
end try

begin catch
	if error_number() = 0
	print 'Failed Error because of insert into Identity.';
	else 
	print 'Passed Error because of insert into Identity.';
end catch


print ''
print ''
Print 'Test Use ColumnNameNoInsert to stop insert into Identity.'
if object_id('a') is not null drop table a;
if object_id('b') is not null drop table b;
go

delete ColumnNameNoInsert;

insert into ColumnNameNoInsert values ('rowid');

Create table a(rowid int identity primary key, a int, b int, c int);
Create table b(rowid int identity primary key, a int , b int,  c int);

insert into a(a, b, c)
values (1, 2, 3);

exec udp_CopyData 
	@p_SourceTable = 'a',
	@p_DestinationTable = 'b',
	--@p_SourceDatabase varchar(130) = null,
	--@p_SourceServer varchar(130) = null,
	--@p_SourceWhere varchar(1000) = '1=1',
	--@p_DestinationDatabase varchar(130) = null,
	--@p_DestinationServer varchar(130) = null,
	@p_InsertIntoPrimaryKeyFlag = 1,
	@p_PrintFlag = 1,
	@p_ExecuteFlag = 1;

if exists(
select a, b, c from a
except
select a, b, c from b)
print 'Failed Use ColumnNameNoInsert to stop insert into Identity.';
else 
print 'Passed Use ColumnNameNoInsert to stop insert into Identity.';



print ''
print ''
Print 'Test @p_InsertIntoPrimaryKeyFlag to stop insert into primary key.'
if object_id('a') is not null drop table a;
if object_id('b') is not null drop table b;
go

delete ColumnNameNoInsert;


Create table a(rowid int identity primary key, a int, b int, c int);
Create table b(rowid int identity primary key, a int , b int,  c int);

insert into a(a, b, c)
values (1, 2, 3);

exec udp_CopyData 
	@p_SourceTable = 'a',
	@p_DestinationTable = 'b',
	--@p_SourceDatabase varchar(130) = null,
	--@p_SourceServer varchar(130) = null,
	--@p_SourceWhere varchar(1000) = '1=1',
	--@p_DestinationDatabase varchar(130) = null,
	--@p_DestinationServer varchar(130) = null,
	@p_InsertIntoPrimaryKeyFlag = 0,
	@p_PrintFlag = 1,
	@p_ExecuteFlag = 1;

if exists(
select a, b, c from a
except
select a, b, c from b)
print 'Failed @p_InsertIntoPrimaryKeyFlag to stop insert into primary key.';
else 
print 'Passed @p_InsertIntoPrimaryKeyFlag to stop insert into primary key.';


print ''
print ''
Print 'Test match columns through ColumnNameMatch table.'
if object_id('a') is not null exec('drop table a');
if object_id('b') is not null exec('drop table b');
go

delete ColumnNameNoInsert;
delete ColumnNameMatch;

insert into ColumnNameMatch(SourceColumnName, DestinationColumnName) values ('RowID', 'SourceRowID');

Create table a(rowid int identity primary key, a int, b int, c int);
Create table b(rowid int identity primary key, a int , b int,  c int, SourceRowID int);

insert into a(a, b, c)
values (1, 2, 3);

exec udp_CopyData 
	@p_SourceTable = 'a',
	@p_DestinationTable = 'b',
	--@p_SourceDatabase varchar(130) = null,
	--@p_SourceServer varchar(130) = null,
	--@p_SourceWhere varchar(1000) = '1=1',
	--@p_DestinationDatabase varchar(130) = null,
	--@p_DestinationServer varchar(130) = null,
	@p_InsertIntoPrimaryKeyFlag = 0,
	@p_PrintFlag = 1,
	@p_ExecuteFlag = 1;

if exists(
select RowID, a, b, c from a
except
select SourceRowID, a, b, c from b)
print 'Failed match columns through ColumnNameMatch table.';
else 
print 'Passed match columns through ColumnNameMatch table.';


print ''
print ''
Print 'Test ColumnNameNoMatch and @p_PrimaryKeyColumnNoInsert together.'
if object_id('a') is not null drop table a;
if object_id('b') is not null drop table b;
go

delete ColumnNameNoInsert;

insert into ColumnNameNoInsert values ('UserName');
insert into ColumnNameNoInsert values ('rowid');

Create table a(rowid int identity primary key, a int, b int, c int, UserName int);
Create table b(rowid int identity primary key, a int , b int,  c int, UserName int);

insert into a(a, b, c)
values (1, 2, 3);

exec udp_CopyData 
	@p_SourceTable = 'a',
	@p_DestinationTable = 'b',
	--@p_SourceDatabase varchar(130) = null,
	--@p_SourceServer varchar(130) = null,
	--@p_SourceWhere varchar(1000) = '1=1',
	--@p_DestinationDatabase varchar(130) = null,
	--@p_DestinationServer varchar(130) = null,
	@p_InsertIntoPrimaryKeyFlag = 0,
	@p_PrintFlag = 1,
	@p_ExecuteFlag = 1;

if exists(
select a, b, c from a
except
select a, b, c from b)
print 'Failed ColumnNameNoMatch and @p_PrimaryKeyColumnNoInsert together.';
else 
print 'Passed ColumnNameNoMatch and @p_PrimaryKeyColumnNoInsert together.';
