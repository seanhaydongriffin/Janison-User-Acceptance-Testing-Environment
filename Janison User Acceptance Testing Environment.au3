#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseUpx=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;#RequireAdmin
;#AutoIt3Wrapper_usex64=n
#include <SQLite.au3>
#include <SQLite.dll.au3>
#include <Toast.au3>
#include <Octopus.au3>
#include <Confluence.au3>
#include <Date.au3>

Local $app_name = "Janison User Acceptance Testing Environment"

; Authentication

Local $ini_filename = @ScriptDir & "\" & $app_name & ".ini"
_ConfluenceAuthenticationWithToast($app_name, "https://janisoncls.atlassian.net", $ini_filename)
_ConfluenceAuthenticationWithToast($app_name, "https://janisoncls.atlassian.net", $ini_filename)
_OctopusDomainSet("https://octopus.janison.com.au")
_OctopusLogin("")

; Page header

$storage_format = '<a href=\"https://janisoncls.atlassian.net/wiki/download/attachments/494207048/Janison%20User%20Acceptance%20Testing%20Environment%20portable.exe\">Click to update page</a><br /><br />'

; Reports

$storage_format = $storage_format &	"<table><tbody><tr><th>Project</th><th>Time</th><th>State</th></tr>" & @CRLF

_Toast_Show(0, $app_name, "Getting deployments", -300, False, True)

Local $deployment = _OctopusGetLatestTenantIdsDeploymentIdTaskIdCreatedForEnvironment("Environments-30")

_Toast_Show(0, $app_name, "Getting deployment states and tenants", -300, False, True)

for $deployment_num = 0 to (UBound($deployment) - 1)

	Local $tenant = _OctopusGetTenantName($deployment[$deployment_num][0])
;	Local $deployment_id = $deployment[$deployment_num][1]
	Local $created = $deployment[$deployment_num][2]
	Local $state = _OctopusGetTaskState($deployment[$deployment_num][3])

;	$output = $output & $tenant & "	" & $deployment_id & "	" & $created & "	" & $state & @CRLF
	$storage_format = $storage_format & "<tr><td>" & $tenant & "</td><td>" & $created & "</td><td>" & $state & "</td></tr>" & @CRLF
Next

$storage_format = $storage_format &	"</tbody></table>" & @CRLF

; Update Confluence

_Toast_Show(0, $app_name, "Uploading reports to confluence", -300, False, True)
Update_Confluence_Page("https://janisoncls.atlassian.net", "JAST", "495845841", "495714970", "User Acceptance Testing Environment", $storage_format)

; Shutdown

_JiraShutdown()
_Toast_Show(0, $app_name, "Done. Refresh the page in Confluence.", -3, False, True)
Sleep(3000)
