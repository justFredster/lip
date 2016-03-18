USE [pie_lip]
GO
/****** Object:  StoredProcedure [dbo].[csp_lip_getxmldatabase_wrapper]    Script Date: 2016-03-16 08:50:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Written by: JKA, PDE and FER, Lundalogik AB
-- Created: 2016-01-25

-- Called by the LIP Package Builder. Returns relevant XML structure for the database.

ALTER PROCEDURE [dbo].[csp_lip_getxmldatabase_wrapper]
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
	SET @subxml = N'<database><tables>'
	
	-- Remove system tables
	SET @xml.modify('delete (/database/table[@idtable<1000])[*]')

	-- Remove system fields
	SET @xml.modify('delete (/database/table[@idfield<1000])[*]')
	
	DECLARE @procedurexml XML	
	SELECT @procedurexml = (
	SELECT o.name, CAST(CAST(m.definition AS VARBINARY(MAX)) AS IMAGE) AS definition FROM sys.objects o
	INNER JOIN sys.sql_modules m ON o.object_id = m.object_id
	WHERE o.name NOT LIKE 'lfn%' AND o.name NOT LIKE '%lsp%'
	AND (type = 'P' OR type = 'TF' OR type = 'fn')
	FOR XML PATH('ProcedureOrFunction'), ROOT('sql'), BINARY BASE64
	)
	SELECT @subxml = @subxml + CAST(T.C.query('.') AS NVARCHAR(MAX))
	FROM @xml.nodes('/database/table') AS T(C) 
	
	SET @subXml = @subxml + '</tables>' + CAST(@procedureXml AS nvarchar(MAX)) + '</database>'


	-- Return data to client
	SELECT @subxml
END
