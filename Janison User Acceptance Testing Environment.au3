#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_UseUpx=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;#RequireAdmin
;#AutoIt3Wrapper_usex64=n
#include <CLR.Au3>
#include <Toast.au3>
#include <Octopus.au3>
#include <Confluence.au3>
#include <Date.au3>

Local $app_name = "Janison User Acceptance Testing Environment"

; Authentication

Local $ini_filename = @ScriptDir & "\" & $app_name & ".ini"
Global $azure_authenticated = False
_ConfluenceAuthenticationWithToast($app_name, "https://janisoncls.atlassian.net", $ini_filename)
_ConfluenceAuthenticationWithToast($app_name, "https://janisoncls.atlassian.net", $ini_filename)
_OctopusDomainSet("https://octopus.janison.com.au")
_OctopusLogin("API-YGNPW8QJMAS38DEY9ASYENSWQ")

; Page header

$storage_format = '<a href=\"https://janisoncls.atlassian.net/wiki/download/attachments/494207048/Janison%20User%20Acceptance%20Testing%20Environment%20portable.exe\">Click to update page</a><br /><br />'

; Reports

$storage_format = $storage_format &	'<table data-layout=\"wide\"><colgroup><col style=\"width:242px;\"/><col style=\"width:109px;\"/><col style=\"width:81px;\"/><col style=\"width:296px;\"/><col style=\"width:232px;\"/></colgroup><tbody><tr><th>Project</th><th>Time</th><th>State</th><th>Global Url</th><th>Queued By</th></tr>' & @CRLF

_Toast_Show(0, $app_name, "Getting deployments", -300, False, True)

Local $deployment = _OctopusGetLatestTenantIdsDeploymentIdTaskIdCreatedForEnvironment("Environments-30")

_Toast_Show(0, $app_name, "Getting deployment states and tenants", -300, False, True)

for $deployment_num = 0 to (UBound($deployment) - 1)

	Local $tenant_id = $deployment[$deployment_num][0]
	Local $deployment_id = $deployment[$deployment_num][1]
	Local $created = $deployment[$deployment_num][2]
	Local $task_id = $deployment[$deployment_num][3]

	Local $deployment_queued_username = _OctopusGetDeploymentQueuedEventUsername($deployment_id)
	Local $tenant_name = _OctopusGetTenantName($tenant_id)
	_OctopusGetTask($task_id)
	Local $decoded_json = Json_Decode($octopus_json)
	Local $state = Json_Get($decoded_json, '.Task.State')
	Local $global_url = ""
	Local $tmp_arr = StringRegExp($octopus_json, '\"Global Url       : (.*)\"', 1)

	if @error = 0 Then

		$global_url = $tmp_arr[0]
	EndIf

	$storage_format = $storage_format & "<tr><td>" & $tenant_name & "</td><td>" & $created & "</td><td>" & $state & "</td><td>" & $global_url & "</td><td>" & $deployment_queued_username & "</td></tr>" & @CRLF
Next

$storage_format = $storage_format &	"</tbody></table>" & @CRLF

; Azure Scaling Information

$storage_format = $storage_format &	'<table data-layout=\"wide\"><colgroup><col style=\"width:160px;\"/><col style=\"width:240px;\"/><col style=\"width:150px;\"/><col style=\"width:200px;\"/><col style=\"width:50px;\"/></colgroup><tbody><tr><th>Azure Subscription</th><th>Resource Grp</th><th>DB Server</th><th>DB Name</th><th>Scale</th></tr>' & @CRLF
_Toast_Show(0, $app_name, "Getting Azure Scaling Data", -300, False, True)

; Authenticate to Azure if required...

AzureAuth()

; Query Azure subscriptions

Local $ps_script_arr[2]
local $ps_script_arr2[1]
Local $name_width = 9999
;$ps_script_arr2[0] = "Get-AzureRmSubscription"
;$str = _Run_PSHost_Script($ps_script_arr2)
;Local $subscription_arr = StringSplit($str, @CRLF, 3)
;Local $name_width = StringInStr($subscription_arr[1], " Id ", 1) - 1
;_ArrayDelete($subscription_arr, 0)
;_ArrayDelete($subscription_arr, 0)
;_ArrayDelete($subscription_arr, 0)

; most of the subscriptions in the list above do not have a SIT DB
;	to save runtime we disable above and instead focus on a hardcoded list of subscriptions that do have a SIT DB below ...

Local $subscription_arr[3]
$subscription_arr[0] = "LearningDevTest"
$subscription_arr[1] = "ECSA"
$subscription_arr[2] = "AssessmentDevTest"

for $subscription_num = 0 to (UBound($subscription_arr) - 1)

	Local $subscription_name = StringStripWS(StringLeft($subscription_arr[$subscription_num], $name_width), 3)

	if StringLen($subscription_name) < 1 Then ExitLoop

	; Query Azure ...

	$ps_script_arr[0] = "Select-AzureRmSubscription -Subscription '" & $subscription_name & "'"
	$ps_script_arr[1] = "Get-AzureRmResource -ResourceType 'Microsoft.Sql/servers' -ResourceGroupName '*-UAT'"
	$str = _Run_PSHost_Script($ps_script_arr)

	if StringLen($str) > 0 Then

		Local $server_name_arr = StringRegExp($str, "(?m)^Name *: (.*)$", 3)

		If @error = 0 Then

			Local $resource_group_name_database_name_arr = StringRegExp($str, "(?m)^ResourceGroupName *: (.*)$", 3)

			for $server_num = 0 to (UBound($server_name_arr) - 1)

				$ps_script_arr2[0] = "Get-AzureRmSqlDatabase -ResourceGroupName '" & $resource_group_name_database_name_arr[$server_num] & "' -ServerName '" & $server_name_arr[$server_num] & "' -DatabaseName '" & $resource_group_name_database_name_arr[$server_num] & "'"
				$str = _Run_PSHost_Script($ps_script_arr2)
				Local $scale = "?"

				if StringLen($str) > 0 Then

					$sql_db_arr = StringRegExp($str, "(?m)CurrentServiceObjectiveName *: (.*)$", 1)
					$scale = $sql_db_arr[0]
				EndIf

				$storage_format = $storage_format & "<tr><td>" & $subscription_name & "</td><td>" & $resource_group_name_database_name_arr[$server_num] & "</td><td>" & $server_name_arr[$server_num] & "</td><td>" & $resource_group_name_database_name_arr[$server_num] & "</td><td>" & $scale & "</td></tr>" & @CRLF
			Next
		EndIf
	EndIf
Next

$storage_format = $storage_format &	"</tbody></table>" & @CRLF

; Update Confluence

_Toast_Show(0, $app_name, "Uploading reports to confluence", -300, False, True)
Update_Confluence_Page("https://janisoncls.atlassian.net", "JAST", "495845841", "495714970", "User Acceptance Testing Environment", $storage_format)

; Shutdown

_JiraShutdown()
_Toast_Show(0, $app_name, "Done. Refresh the page in Confluence.", -3, False, True)
Sleep(3000)

Func AzureAuth()

	if $azure_authenticated = False Then

		Local $ps_script_arr[1]
		$ps_script_arr[0] = "Get-AzureRmSubscription"
		$str = _Run_PSHost_Script($ps_script_arr)

		if StringLen($str) = 0 Then

			$ps_script_arr[0] = "Login-AzureRmAccount"
			$str = _Run_PSHost_Script($ps_script_arr)
		EndIf

	EndIf

	$azure_authenticated = True

EndFunc

Func _Run_PSHost_Script($PSScriptArr)

	Local $output_file = @ScriptDir & "\PShost.txt"
	FileDelete($output_file)

	Local $oAssembly = _CLR_LoadLibrary("System.Management.Automation")
    Local $pAssemblyType = 0
    $oAssembly.GetType_2("System.Management.Automation.PowerShell", $pAssemblyType)
    Local $oActivatorType = ObjCreateInterface($pAssemblyType, $sIID_IType, $sTag_IType)
    Local $pObjectPS = 0
    $oActivatorType.InvokeMember_3("Create", 0x158, 0, 0, 0, $pObjectPS)

	for $i = 0 to UBound($PSScriptArr) - 1

		$pObjectPS.AddScript($PSScriptArr[$i])
	Next

	$pObjectPS.AddCommand("Out-File")
	$pObjectPS.AddArgument($output_file)
    $objAsync = $pObjectPS.BeginInvoke()

    While $objAsync.IsCompleted = False
        ContinueLoop
    WEnd

    $objPsCollection = $pObjectPS.EndInvoke($objAsync)
	$str = FileRead($output_file)
	FileDelete($output_file)

	Return $str
EndFunc
