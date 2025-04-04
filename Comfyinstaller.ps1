mkdir C:\comfy
cd C:\comfy

invoke-webrequest -Uri "https://github.com/neasej12/projects/raw/refs/heads/main/comfyui-local.zip" -outfile "C:\comfy\comfyui-local.zip" 
expand-archive "C:\comfy\comfyui-local.zip" -destinationpath "C:\comfy"
.\one-click-comfyui.bat