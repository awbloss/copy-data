use CopyData;
go
if not exists(select * from sys.schemas where name = 'cat') exec('create schema cat');
go
if not exists(select * from sys.schemas where name = 'dog') exec('create schema dog');
go




Set nocount on;
print 'Make code work for schemas and add test.'
-----------------------------------------------
Print 'Test Matching Column Names.'

delete ColumnNameNoInsert;

if object_id('cat.a') is not null drop table cat.a;
if object_id('dog.b') is not null drop table dog.b;
go

Create table cat.a(a int, b int, c int);
Create table dog.b(a int , b int,  c int);

insert into cat.a(a, b, c)
values (1, 2, 3);

delete dog.b;

exec udp_CopyData 
    @p_SourceTable = 'cat.a',
    @p_DestinationTable = 'dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
    --@p_SourceDatabase varchar(130) = null,
    --@p_SourceServer varchar(130) = null,
    --@p_SourceWhere varchar(1000) = '1=1',
    --@p_DestinationDatabase varchar(130) = null,
    --@p_DestinationServer varchar(130) = null,
    @p_InsertIntoPrimaryKeyFlag = 1,
    @p_PrintFlag = 1,
    @p_ExecuteFlag = 1;

if exists(select a, b, c from cat.a
except
select a, b, c from dog.b)
print 'Failed Matching Column Names.'
else 
print 'Passed Matching Column Names.';


print ''
print ''
print 'Test Unmatched Column In Source.'
alter table cat.a add d int;
delete dog.b;
exec udp_CopyData 
    @p_SourceTable = 'cat.a',
    @p_DestinationTable = 'dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
    --@p_SourceDatabase varchar(130) = null,
    --@p_SourceServer varchar(130) = null,
    --@p_SourceWhere varchar(1000) = '1=1',
    --@p_DestinationDatabase varchar(130) = null,
    --@p_DestinationServer varchar(130) = null,
    @p_InsertIntoPrimaryKeyFlag = 1,
    @p_PrintFlag = 1,
    @p_ExecuteFlag = 1

if exists(select a, b, c from cat.a
except
select a, b, c from dog.b)
print 'Failed Unmatched Column In Source.'
else 
print 'Passed Unmatched Column In Source.';


print ''
print ''
Print 'Test Unnmatched Column in Destination.'
alter table dog.b add e int;
delete dog.b;

exec udp_CopyData 
    @p_SourceTable = 'cat.a',
    @p_DestinationTable = 'dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
    --@p_SourceDatabase varchar(130) = null,
    --@p_SourceServer varchar(130) = null,
    --@p_SourceWhere varchar(1000) = '1=1',
    --@p_DestinationDatabase varchar(130) = null,
    --@p_DestinationServer varchar(130) = null,
    @p_InsertIntoPrimaryKeyFlag = 1,
    @p_PrintFlag = 1,
    @p_ExecuteFlag = 1

if exists(
select a, b, c from cat.a
except
select a, b, c from dog.b)
print 'Failed Unnmatched Column in Destination.'
else 
print 'Passed Unnmatched Column in Destination.';


print ''
print ''
Print 'Test Error because of insert into Identity.'
if object_id('cat.a') is not null drop table cat.a;
if object_id('dog.b') is not null drop table dog.b;

delete ColumnNameNoInsert;

create table cat.a(rowid int identity primary key, a int, b int, c int);
create table dog.b(rowid int identity primary key, a int , b int,  c int);

insert into cat.a(a, b, c)
values (1, 2, 3);

begin try
	exec udp_CopyData 
		@p_SourceTable = 'cat.a',
		@p_DestinationTable = 'dog.b',
		--@p_SourceSchema = 'cat',
		--@p_DestinationSchema = 'dog',
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
if object_id('cat.a') is not null drop table cat.a;
if object_id('dog.b') is not null drop table dog.b;

delete ColumnNameNoInsert;

insert into ColumnNameNoInsert values ('rowid');

create table cat.a(rowid int identity primary key, a int, b int, c int);
create table dog.b(rowid int identity primary key, a int , b int,  c int);

insert into cat.a(a, b, c)
values (1, 2, 3);

exec udp_CopyData 
	@p_SourceTable = 'cat.a',
	@p_DestinationTable = 'dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
	--@p_SourceDatabase varchar(130) = null,
	--@p_SourceServer varchar(130) = null,
	--@p_SourceWhere varchar(1000) = '1=1',
	--@p_DestinationDatabase varchar(130) = null,
	--@p_DestinationServer varchar(130) = null,
	@p_InsertIntoPrimaryKeyFlag = 1,
	@p_PrintFlag = 1,
	@p_ExecuteFlag = 1;

if exists(
select a, b, c from cat.a
except
select a, b, c from dog.b)
print 'Failed Use ColumnNameNoInsert to stop insert into Identity.';
else 
print 'Passed Use ColumnNameNoInsert to stop insert into Identity.';



print ''
print ''
Print 'Test @p_InsertIntoPrimaryKeyFlag to stop insert into primary key.'
if object_id('cat.a') is not null drop table cat.a;
if object_id('dog.b') is not null drop table dog.b;

delete ColumnNameNoInsert;


create table cat.a(rowid int identity primary key, a int, b int, c int);
create table dog.b(rowid int identity primary key, a int , b int,  c int);

insert into cat.a(a, b, c)
values (1, 2, 3);

exec udp_CopyData 
	@p_SourceTable = 'cat.a',
	@p_DestinationTable = 'dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
	--@p_SourceDatabase varchar(130) = null,
	--@p_SourceServer varchar(130) = null,
	--@p_SourceWhere varchar(1000) = '1=1',
	--@p_DestinationDatabase varchar(130) = null,
	--@p_DestinationServer varchar(130) = null,
	@p_InsertIntoPrimaryKeyFlag = 0,
	@p_PrintFlag = 1,
	@p_ExecuteFlag = 1;

if exists(
select a, b, c from cat.a
except
select a, b, c from dog.b)
print 'Failed @p_InsertIntoPrimaryKeyFlag to stop insert into primary key.';
else 
print 'Passed @p_InsertIntoPrimaryKeyFlag to stop insert into primary key.';


print ''
print ''
Print 'Test match columns through ColumnNameMatch table.'
if object_id('cat.a') is not null exec('drop table cat.a');
if object_id('dog.b') is not null exec('drop table dog.b');
go

delete ColumnNameNoInsert;
delete ColumnNameMatch;

insert into ColumnNameMatch(SourceColumnName, DestinationColumnName) values ('RowID', 'SourceRowID');

create table cat.a(rowid int identity primary key, a int, b int, c int);
create table dog.b(rowid int identity primary key, a int , b int,  c int, SourceRowID int);

insert into cat.a(a, b, c)
values (1, 2, 3);

exec udp_CopyData 
	@p_SourceTable = 'cat.a',
	@p_DestinationTable = 'dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
	--@p_SourceDatabase varchar(130) = null,
	--@p_SourceServer varchar(130) = null,
	--@p_SourceWhere varchar(1000) = '1=1',
	--@p_DestinationDatabase varchar(130) = null,
	--@p_DestinationServer varchar(130) = null,
	@p_InsertIntoPrimaryKeyFlag = 0,
	@p_PrintFlag = 1,
	@p_ExecuteFlag = 1;

if exists(
select RowID, a, b, c from cat.a
except
select SourceRowID, a, b, c from dog.b)
print 'Failed match columns through ColumnNameMatch table.';
else 
print 'Passed match columns through ColumnNameMatch table.';


print ''
print ''
Print 'Test ColumnNameNoMatch and @p_PrimaryKeyColumnNoInsert together.'
if object_id('cat.a') is not null drop table cat.a;
if object_id('dog.b') is not null drop table dog.b;

delete ColumnNameNoInsert;

--insert into ColumnNameNoInsert values ('UserName');
insert into ColumnNameNoInsert values ('rowid');

create table cat.a(rowid int identity primary key, a int, b int, c int, UserName int);
create table dog.b(rowid int identity primary key, a int , b int,  c int, UserName int);

insert into cat.a(a, b, c)
values (1, 2, 3);

exec udp_CopyData 
	@p_SourceTable = 'cat.a',
	@p_DestinationTable = 'dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
	--@p_SourceDatabase varchar(130) = null,
	--@p_SourceServer varchar(130) = null,
	--@p_SourceWhere varchar(1000) = '1=1',
	--@p_DestinationDatabase varchar(130) = null,
	--@p_DestinationServer varchar(130) = null,
	@p_InsertIntoPrimaryKeyFlag = 0,
	@p_PrintFlag = 1,
	@p_ExecuteFlag = 1;

if exists(
select a, b, c from cat.a
except
select a, b, c from dog.b)
print 'Failed ColumnNameNoMatch and @p_PrimaryKeyColumnNoInsert together.';
else 
print 'Passed ColumnNameNoMatch and @p_PrimaryKeyColumnNoInsert together.';
