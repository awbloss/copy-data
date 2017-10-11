/*
create database jill;
go
use jill;
go
create schema cat

create database jack;
go
use jack;
go
create schema dog;

*/
use CopyData



Set nocount on;
print 'Make code work for schemas and add test.'
-----------------------------------------------
Print 'Test Matching Column Names.'

delete ColumnNameNoInsert;

if object_id('jill.cat.a') is not null drop table jill.cat.a;
if object_id('jack.dog.b') is not null drop table jack.dog.b;
go

Create table jill.cat.a(a int, b int, c int);
Create table jack.dog.b(a int , b int,  c int);

insert into jill.cat.a(a, b, c)
values (1, 2, 3);

delete jack.dog.b;

exec udp_CopyData 
    @p_SourceTable = 'jill.cat.a',
    @p_DestinationTable = 'jack.dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
    --@p_SourceDatabase = 'jill',
    --@p_SourceServer varchar(130) = null,
    --@p_SourceWhere varchar(1000) = '1=1',
    --@p_DestinationDatabase = 'jack',
    --@p_DestinationServer varchar(130) = null,
    @p_InsertIntoPrimaryKeyFlag = 1,
    @p_PrintFlag = 1,
    @p_ExecuteFlag = 1;

if exists(select a, b, c from jill.cat.a
except
select a, b, c from jack.dog.b)
print 'Failed Matching Column Names.'
else 
print 'Passed Matching Column Names.';


print ''
print ''
print 'Test Unmatched Column In Source.'
alter table jill.cat.a add d int;
delete jack.dog.b;
exec udp_CopyData 
    @p_SourceTable = 'jill.cat.a',
    @p_DestinationTable = 'jack.dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
    --@p_SourceDatabase = 'jill',
    --@p_SourceServer varchar(130) = null,
    --@p_SourceWhere varchar(1000) = '1=1',
    --@p_DestinationDatabase = 'jack',
    --@p_DestinationServer varchar(130) = null,
    @p_InsertIntoPrimaryKeyFlag = 1,
    @p_PrintFlag = 1,
    @p_ExecuteFlag = 1

if exists(select a, b, c from jill.cat.a
except
select a, b, c from jack.dog.b)
print 'Failed Unmatched Column In Source.'
else 
print 'Passed Unmatched Column In Source.';


print ''
print ''
Print 'Test Unnmatched Column in Destination.'
alter table jack.dog.b add e int;
delete jack.dog.b;

exec udp_CopyData 
    @p_SourceTable = 'jill.cat.a',
    @p_DestinationTable = 'jack.dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
    --@p_SourceDatabase = 'jill',
    --@p_SourceServer varchar(130) = null,
    --@p_SourceWhere varchar(1000) = '1=1',
    --@p_DestinationDatabase = 'jack',
    --@p_DestinationServer varchar(130) = null,
    @p_InsertIntoPrimaryKeyFlag = 1,
    @p_PrintFlag = 1,
    @p_ExecuteFlag = 1

if exists(
select a, b, c from jill.cat.a
except
select a, b, c from jack.dog.b)
print 'Failed Unnmatched Column in Destination.'
else 
print 'Passed Unnmatched Column in Destination.';


print ''
print ''
Print 'Test Error because of insert into Identity.'
if object_id('jill.cat.a') is not null drop table jill.cat.a;
if object_id('jack.dog.b') is not null drop table jack.dog.b;

delete ColumnNameNoInsert;

create table jill.cat.a(rowid int identity primary key, a int, b int, c int);
create table jack.dog.b(rowid int identity primary key, a int , b int,  c int);

insert into jill.cat.a(a, b, c)
values (1, 2, 3);

begin try
	exec udp_CopyData 
		@p_SourceTable = 'jill.cat.a',
		@p_DestinationTable = 'jack.dog.b',
		--@p_SourceSchema = 'cat',
		--@p_DestinationSchema = 'dog',
		--@p_SourceDatabase = 'jill',
		--@p_SourceServer varchar(130) = null,
		--@p_SourceWhere varchar(1000) = '1=1',
		--@p_DestinationDatabase = 'jack',
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
if object_id('jill.cat.a') is not null drop table jill.cat.a;
if object_id('jack.dog.b') is not null drop table jack.dog.b;

delete ColumnNameNoInsert;

insert into ColumnNameNoInsert values ('rowid');

create table jill.cat.a(rowid int identity primary key, a int, b int, c int);
create table jack.dog.b(rowid int identity primary key, a int , b int,  c int);

insert into jill.cat.a(a, b, c)
values (1, 2, 3);

exec udp_CopyData 
	@p_SourceTable = 'jill.cat.a',
	@p_DestinationTable = 'jack.dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
	--@p_SourceDatabase = 'jill',
	--@p_SourceServer varchar(130) = null,
	--@p_SourceWhere varchar(1000) = '1=1',
	--@p_DestinationDatabase = 'jack',
	--@p_DestinationServer varchar(130) = null,
	@p_InsertIntoPrimaryKeyFlag = 1,
	@p_PrintFlag = 1,
	@p_ExecuteFlag = 1;

if exists(
select a, b, c from jill.cat.a
except
select a, b, c from jack.dog.b)
print 'Failed Use ColumnNameNoInsert to stop insert into Identity.';
else 
print 'Passed Use ColumnNameNoInsert to stop insert into Identity.';



print ''
print ''
Print 'Test @p_InsertIntoPrimaryKeyFlag to stop insert into primary key.'
if object_id('jill.cat.a') is not null drop table jill.cat.a;
if object_id('jack.dog.b') is not null drop table jack.dog.b;

delete ColumnNameNoInsert;


create table jill.cat.a(rowid int identity primary key, a int, b int, c int);
create table jack.dog.b(rowid int identity primary key, a int , b int,  c int);

insert into jill.cat.a(a, b, c)
values (1, 2, 3);

exec udp_CopyData 
	@p_SourceTable = 'jill.cat.a',
	@p_DestinationTable = 'jack.dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
	--@p_SourceDatabase = 'jill',
	--@p_SourceServer varchar(130) = null,
	--@p_SourceWhere varchar(1000) = '1=1',
	--@p_DestinationDatabase = 'jack',
	--@p_DestinationServer varchar(130) = null,
	@p_InsertIntoPrimaryKeyFlag = 0,
	@p_PrintFlag = 1,
	@p_ExecuteFlag = 1;

if exists(
select a, b, c from jill.cat.a
except
select a, b, c from jack.dog.b)
print 'Failed @p_InsertIntoPrimaryKeyFlag to stop insert into primary key.';
else 
print 'Passed @p_InsertIntoPrimaryKeyFlag to stop insert into primary key.';


print ''
print ''
Print 'Test match columns through ColumnNameMatch table.'
if object_id('jill.cat.a') is not null exec('drop table jill.cat.a');
if object_id('jack.dog.b') is not null exec('drop table jack.dog.b');
go

delete ColumnNameNoInsert;
delete ColumnNameMatch;

insert into ColumnNameMatch(SourceColumnName, DestinationColumnName) values ('RowID', 'SourceRowID');

create table jill.cat.a(rowid int identity primary key, a int, b int, c int);
create table jack.dog.b(rowid int identity primary key, a int , b int,  c int, SourceRowID int);

insert into jill.cat.a(a, b, c)
values (1, 2, 3);

exec udp_CopyData 
	@p_SourceTable = 'jill.cat.a',
	@p_DestinationTable = 'jack.dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
	--@p_SourceDatabase = 'jill',
	--@p_SourceServer varchar(130) = null,
	--@p_SourceWhere varchar(1000) = '1=1',
	--@p_DestinationDatabase = 'jack',
	--@p_DestinationServer varchar(130) = null,
	@p_InsertIntoPrimaryKeyFlag = 0,
	@p_PrintFlag = 1,
	@p_ExecuteFlag = 1;

if exists(
select RowID, a, b, c from jill.cat.a
except
select SourceRowID, a, b, c from jack.dog.b)
print 'Failed match columns through ColumnNameMatch table.';
else 
print 'Passed match columns through ColumnNameMatch table.';


print ''
print ''
Print 'Test ColumnNameNoMatch and @p_PrimaryKeyColumnNoInsert together.'
if object_id('jill.cat.a') is not null drop table jill.cat.a;
if object_id('jack.dog.b') is not null drop table jack.dog.b;

delete ColumnNameNoInsert;

--insert into ColumnNameNoInsert values ('UserName');
insert into ColumnNameNoInsert values ('rowid');

create table jill.cat.a(rowid int identity primary key, a int, b int, c int, UserName int);
create table jack.dog.b(rowid int identity primary key, a int , b int,  c int, UserName int);

insert into jill.cat.a(a, b, c)
values (1, 2, 3);

exec udp_CopyData 
	@p_SourceTable = 'jill.cat.a',
	@p_DestinationTable = 'jack.dog.b',
	--@p_SourceSchema = 'cat',
    --@p_DestinationSchema = 'dog',
	--@p_SourceDatabase = 'jill',
	--@p_SourceServer varchar(130) = null,
	--@p_SourceWhere varchar(1000) = '1=1',
	--@p_DestinationDatabase = 'jack',
	--@p_DestinationServer varchar(130) = null,
	@p_InsertIntoPrimaryKeyFlag = 0,
	@p_PrintFlag = 1,
	@p_ExecuteFlag = 1;

if exists(
select a, b, c from jill.cat.a
except
select a, b, c from jack.dog.b)
print 'Failed ColumnNameNoMatch and @p_PrimaryKeyColumnNoInsert together.';
else 
print 'Passed ColumnNameNoMatch and @p_PrimaryKeyColumnNoInsert together.';
