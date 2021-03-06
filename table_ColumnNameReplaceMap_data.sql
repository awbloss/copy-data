GO
/****** Object:  Table [dbo].[ColumnNameMatch]    Script Date: 12/31/2016 1:38:31 PM ******/

/*

select * from columnNameMatch


*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ColumnNameMatch](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[SourceColumnName] [varchar](130) NOT NULL,
	[DestinationColumnName] [varchar](130) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
SET IDENTITY_INSERT [dbo].[ColumnNameMatch] ON 

INSERT [dbo].[ColumnNameMatch] ([id], [SourceColumnName], [DestinationColumnName]) VALUES (1031, N'[Lion]', N'[Feline]')
SET IDENTITY_INSERT [dbo].[ColumnNameMatch] OFF
SET ANSI_PADDING ON

GO
/****** Object:  Index [ColumnNameMatches_UniqueMatch]    Script Date: 12/31/2016 1:38:31 PM ******/
ALTER TABLE [dbo].[ColumnNameMatch] ADD  CONSTRAINT [ColumnNameMatches_UniqueMatch] UNIQUE NONCLUSTERED 
(
	[SourceColumnName] ASC,
	[DestinationColumnName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
