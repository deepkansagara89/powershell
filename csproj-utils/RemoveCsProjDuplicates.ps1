<#  
.SYNOPSIS  
    Finds all csproj in the supplied path and removes all the duplicate entries.
.DESCRIPTION  
    This script finds all duplicate <content> , <compile> , <Reference>, <EmbeddedResource>, <None>,<Page>,<Resource>,<ProjectReference>,<Folder> entries in csproj files,
    and removes them.
.NOTES  
    File Name  : RemoveCsProjDuplicates.ps1  
    Original Author     : Rodrigo F. Fernandes - github.com/rodrigoff
	extended to support all entries types	Author    : Deep Kansagara
.LINK  
    - base file 
	https://github.com/rodrigoff/powershell/blob/master/csproj-utils/RemoveCsProjDuplicates.ps1 
#>
Param(
    [string]$filePath = $(throw "You must supply a file path")
)

$filePath = Resolve-Path $filePath

"> Searching for project files in $filePath"

$projectFiles = Get-ChildItem -Path $filePath -Include *.csproj -Recurse `
| Where-Object { $_.FullName -notmatch "\\packages\\?" } `
| Select-Object -ExpandProperty FullName
 
"> Found $($projectFiles.Count) project files"
 
Foreach($projectFile in $projectFiles) {
    $xml = [xml] (Get-Content $projectFile)
    
    Write-Host "> $projectFile " -Foreground Green
	
$entries = $xml.Project.ItemGroup.Compile + $xml.Project.ItemGroup.Content +$xml.Project.ItemGroup.Reference + $xml.Project.ItemGroup.EmbeddedResource + $xml.Project.ItemGroup.None + $xml.Project.ItemGroup.Page + $xml.Project.ItemGroup.Resource + $xml.Project.ItemGroup.ProjectReference + $xml.Project.ItemGroup.Folder | Group-Object Include
    
	$duplicateEntries = $entries | Where-Object Count -gt 1

    "- Found $($duplicateEntries.Count) duplicate entries"

    if (!$duplicateEntries) {
        continue
    }
    
    foreach ($duplicateEntry in $duplicateEntries) {
        While ($duplicateEntry.Group.Count -gt 1) {
            $e = $duplicateEntry.Group[0]
            $e.ParentNode.RemoveChild($e) | Out-Null
            $duplicateEntry.Group.Remove($e) | Out-Null
        }
    }

    $xml.Save($projectFile) | Out-Null

    "- Removed $($duplicateEntries.Count) duplicate entries"
}
