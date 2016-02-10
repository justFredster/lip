
/****** Object:  StoredProcedure [dbo].[csp_lip_getxmldatabase_wrapper]    Script Date: 2016-02-10 10:04:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Written by: JKA, PDE and FER, Lundalogik AB
-- Created: 2016-01-25

-- Called by the LIP Package Builder. Returns relevant XML structure for the database.

CREATE PROCEDURE [dbo].[csp_lip_getxmldatabase_wrapper]
	@@lang NVARCHAR(5)
	, @@idcoworker INT = NULL
AS
BEGIN
	-- FLAG_EXTERNALACCESS --
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @xmlasstring NVARCHAR(MAX)
	DECLARE @xml XML
	DECLARE @subxml NVARCHAR(MAX)
	
	-- Get complete xml structure
	EXECUTE lsp_getxmldatabase
		@@lang = @@lang
		, @@setstrings = 1
		, @@user = 1
		, @@fulloutput = 1
		, @@xml = @xmlasstring OUTPUT
	
	-- Escape tokens \ and " to prevent trouble when converting to JSON later on.
	SET @xml = CONVERT(XML, REPLACE(
								REPLACE(@xmlasstring, N'\', N'\\')
								, N'&quot;', N'\&quot;')
							)
	
	-- Only return relevant xml
	SET @subxml = N''
	SELECT @subxml = @subxml + CAST(T.C.query('.') AS NVARCHAR(MAX))
	FROM @xml.nodes('/database/table') AS T(C)
	
	-- Remove system tables
	SET @xml.modify('delete (/database/table[@idtable<1000])[*]')

	-- Remove system fields
	SET @xml.modify('delete (/database/table[@idfield<1000])[*]')
	
	-- Return data to client
	SELECT @subxml
END
