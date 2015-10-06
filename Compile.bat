@Echo off
del ..\System\foxWSFix.*
echo Starting Compile Job...
..\System\UCC make
echo.
pause
