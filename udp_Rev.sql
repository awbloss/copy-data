if object_id('udp_Rev', 'p') is not null
exec('drop procedure udp_Rev');
go

/*
    Created by Andrew Bloss 11/30/2016

    Execute each line of a dynamic cursor.

    udp_Fev can be not be called on a remote server.

    exec udp_rev @p_Cursor = @Cursor, @p_PrintFlag = 1, @p_ExecuteFlag = 1;

    In a production system the print statements should be replaced with inserts within autonomous transactions
    so the inserts are not rolled back if enclosing transaction is rolled back.

*/

create proc udp_Rev 
	@p_Cursor cursor varying output,  
	@p_PrintFlag int = 1,
	@p_ExecuteFlag int = 1
as
begin
    set nocount off;

	declare @q varchar(max);
	
	open @p_Cursor;
	fetch next from @p_Cursor into @q;

    while @@fetch_status >= 0
	begin 
		begin try
			if @p_PrintFlag = 1
            begin
                print isnull(@q, 'q = NULL') + ';';  

                if len(@q) > 4000 
                    select [SQL print from udp_rev] = isnull(@q, 'q = NULL') + ';';  
            end;

			if @p_ExecuteFlag = '1' 
                exec(@q);
		end try

		begin catch
			print 'ERROR IN FOLLOWING CODE: ' + error_message();
			if @p_PrintFlag = '0' print isnull(@q, 'q = NULL') + ';'; 
            throw;
		end catch

        fetch next from @p_Cursor into @q;
	end;
end
go
