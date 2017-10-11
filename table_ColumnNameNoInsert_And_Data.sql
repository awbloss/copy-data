create table ColumnNameNoInsert (ColumnName varchar(130) not null primary key);

insert into ColumnNameNoInsert select '[RowID]';