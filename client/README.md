# Making an API Call

To provide information to the API you will need the two ``.ps1`` files, and PowerShell 6.x or better.

## Execution

You will need to know the servername or ip, and the port the container is using. If your ``docker run`` command contained ``5000:8082`` then your URI below should use 5000 as its port.

```powershell
# cd to the support files' location
./clientcall.ps1 -Uri http://[SERVERNAME OR IP]:[PORT]/api/sysinfo
