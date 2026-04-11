param($ctxOrFileName)
$ctx = Import-CliXml -Path $ctxOrFileName


# to DEBUG, remove this line
#Hide-Console


$ViewModel = [PSCustomObject]@{
    PreFillPath    = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.IO.Path]::GetRandomFileName())
    PrefillContent = @"
Some default "content to Fix", before saving

Username: $env:USERNAME
Computername: $env:COMPUTERNAME
Domain: $env:USERDOMAIN
"@
}



$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Save Text to File" Height="400" Width="550" MinHeight="300" MinWidth="400"
        WindowStartupLocation="CenterScreen"
        >
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0" Text="Enter your text:" Margin="0,0,0,5" FontWeight="SemiBold"/>

        <Border Grid.Row="1" BorderBrush="#CCC" BorderThickness="1" CornerRadius="3" Margin="0,0,0,10">
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <TextBox x:Name="txtContent" 
                         TextWrapping="Wrap" 
                         AcceptsReturn="True" 
                         VerticalAlignment="Stretch"
                         Padding="5"
                         BorderThickness="0"
                         FontFamily="Consolas, Courier New, monospace"
                         Text="{Binding PrefillContent, UpdateSourceTrigger=PropertyChanged}" />
            </ScrollViewer>
        </Border>

        <Grid Grid.Row="2" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Text="Save to:" VerticalAlignment="Center" Margin="0,0,10,0" FontWeight="SemiBold"/>
            <TextBox x:Name="txtPath" Text="{Binding PreFillPath, UpdateSourceTrigger=PropertyChanged}" Grid.Column="1" IsReadOnly="True" Padding="5" Background="#F5F5F5"/>
            <Button x:Name="btnBrowse" Grid.Column="2" Content="Browse..." Width="80" Margin="10,0,0,0"/>
        </Grid>

        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right">
            <Button x:Name="btnSave" Content="Save" Width="80" Margin="0,0,10,0" IsDefault="True"/>
            <Button x:Name="btnCancel" Content="Cancel" Width="80" IsCancel="True"/>
        </StackPanel>
    </Grid>
</Window>
'@

$Elements, $Window = New-WindowXamlString $xaml -Debug

# Bind the DataContext
$Window.DataContext = $ViewModel

$script:Canceled = $true

$Elements.btnBrowse.Add_Click({
    $file = Save-FileDialog -Title "Save Text File" -Filter "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
    if ($file) {
        $Elements.txtPath.Text = $file 
    }
})

$Elements.btnSave.Add_Click({
    # Now we can just read from the ViewModel
    if ([string]::IsNullOrWhiteSpace($ViewModel.PreFillPath)) {
        Show-MessageBox -Message "Please select a file path first." -Title "No Path Selected" -Type "Warning"
        return
    }
    
    # the only case where to save on close
    $script:Canceled = $false
    $Window.Close()
})

$Elements.btnCancel.Add_Click({
    $Window.Close()
})

Write-Host "Opening text editor window..."

# wait for the window to close
$Window | Show-Window

if (-not $script:Canceled) {
    # Read the final text straight from the ViewModel
    $content = $ViewModel.PrefillContent

    try {
        Set-Content -Path $ViewModel.PreFillPath -Value $content
        Write-Host "File saved successfully: $($ViewModel.PreFillPath)"
        Show-MessageBox -Message "File saved successfully to:`n$($ViewModel.PreFillPath)" -Title "Success" -Type "Information"
    }
    catch {
        $errorMsg = "Failed to save file: $_"
        Write-Host $errorMsg
        Show-MessageBox -Message $errorMsg -Title "Error" -Type "Error"
    }
}
else {
    Write-Host "Operation cancelled by user"
}