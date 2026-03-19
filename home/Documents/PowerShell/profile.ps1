# https://github.com/conda/conda/issues/11648
# conda init powershell slows shell startup immensely. #11648
#region conda initialize
# !! Contents within this block are managed by 'conda init' !!
# If (Test-Path "E:\anaconda\Scripts\conda.exe") {
#     (& "E:\anaconda\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | ?{$_} | Invoke-Expression
# }
#endregion

