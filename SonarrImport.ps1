<#Begin User defined variables #>
#Protocol used to access Sonarr. [http|https]
$WebProtocol = 'http'
#Sonarr API key for authentication. Found under Settings-> General-> API.
$ApiKey = '00dfd2f8a4564a77bf0e4e6c280526df'
#Sonarr IP or hostname. This is used to access the Sonarr API                                                                                                                                                                                            
$SonarrHost = 'butler'
#Sonarr port. Default is 8989
$Port = '8989'
#Would you like to receive notifications in the webUI when a file is imported? [$true|$false]
$ClientNotifications = $true
#Types of media to import. Seperate with '|'                                                                                                                                                                                                 
$ExtensionRegex = '.mp4|.mkv|.wmv|.avi'
#Path to media for import on the machine running the script. Use full path; i.e. '/mnt/...'
$MediaDirectoryRelativeToScript = '/mnt/butler/media/tmp/'
#Path to media from Sonarr's perspective. if running in a docker, this may be '/downloads'. If this is running on the same machine as sonarr they can be the same path
$MediaDirectoryRelativeToSonarr = '/downloads/'
##PLEASE NOTE $MediaDirectoryRelativeToSonarr and $MediaDirectoryRelativeToScript must have the same file structure. 
#if $MediaDirectoryRelativeToScript/1.txt exists then $MediaDirectoryRelativeToSonarr/1.txt must exist.
<#End of User Defined Variables#>

#Get media to be imported
$Media = Get-ChildItem -File -Path $MediaDirectoryRelativeToScript | Where-Object {$_.extension -match $ExtensionRegex}
#Add path relative to sonarr variable
$Media = $Media | Select-Object *,@{Name='SonarrPath';Expression={$MediaDirectoryRelativeToSonarr + $_.PSChildName}}
#Forming the connection string to access Sonarr
$URL = $WebProtocol + '://' + $SonarrHost + ':' + $Port + '/api/command?apikey=' + $ApiKey



#Sending Sonarr the commands
foreach($i in $Media.SonarrPath){
    #Form the JSON for the api. This is a hashtable that is converted to JSON using the 'ConvertTo-Json' function
    $JSON = @{
        #Send notifications to the webUI on file import
        'sendUpdatesToClient'=$ClientNotifications;
        'sendUpdates'=$ClientNotifications;
        #This is the part of the api being called
        'name'='DownloadedEpisodesScan';
        #Path to media relative to sonarr
        'path'=$i; 
        #What to do with the files. [move|copy|auto]
        'importmode'='move'
    }|ConvertTo-Json
    
    Invoke-RestMethod -Uri $URL -Method Post -Body $JSON
}