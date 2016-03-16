-- Written by: Jonny Springare
-- Created: 2016-03-16

CREATE PROCEDURE [dbo].[csp_lip_removeTablesAndFields]
	@@idtable INT = NULL
	, @@idfield INT = NULL
	, @@errorMessage NVARCHAR(512) OUTPUT
AS
BEGIN

	-- FLAG_EXTERNALACCESS --
	IF @@idtable IS NOT NULL
	BEGIN
		exec lsp_removetable @@idtable=@@idtable
	END
	ELSE IF @@idfield IS NOT NULL
	BEGIN
		exec lsp_removefield @@idfield=@@idfield
	END
END
