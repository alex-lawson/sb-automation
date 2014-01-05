Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oF = oFSO.OpenTextFile "testplayer.config" ForAppending 1
Set list = CreateObject("System.Collections.ArrayList")

oF.WriteLine("{")
oF.WriteLine("  ""__merge"": [], ")
oF.WriteLine("  ""defaultBlueprints"" : { ")
oF.WriteLine("    ""tier1"" : [ ")

Recurse(oFSO.GetFolder("recipes\"))
Recurse(oFSO.GetFolder("recipes_creative\"))

list.Sort
For i = 0 To list.Count
  oF.Write("      { ""item"" : """ & list.Item(i) & """ }")

Next

oF.Close

Sub Recurse(oFldr)
        For Each oSubFolder In oFldr.SubFolders
             Recurse oSubFolder
        Next
        For Each oFile In oFldr.Files
            list.Add oFSO.GetBaseName(oFile)
        Next
End Sub