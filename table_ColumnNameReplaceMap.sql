/****** Object:  Table [dbo].[ColumnNameReplaceMap]    Script Date: 12/30/2016 12:26:52 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[ColumnNameReplaceMap](
	[StringToReplace] [varchar](100) NOT NULL PRIMARY KEY,
	[ReplacementString] [varchar](100) NOT NULL,
	[XMLCharacterFlag] [bit] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


