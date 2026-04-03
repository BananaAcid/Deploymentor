return @{

    title="Remove unneded C:\ dirs" #optional: if not given, the folder's name is used

    description = "removes \MSOCache, \Intel, \PerfLogs" #optional: detault is empty

    isSelected = $false  #optional: default is false, only used if a profile does not specify this

    # required
    installFn = {
        echo "remove unneded C:\ dirs"
        ("C:\MSOCache", "C:\Intel", "C:\PerfLogs") |
          %{rm -r -fo $_ -ErrorAction SilentlyContinue; if ($?) {echo $_" removed"}}

    }
}