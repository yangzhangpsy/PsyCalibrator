rem You’ll need to run a command from an Administrator Command Prompt to do this. 
rem To launch one, right-click the Start button or press Windows+X 
rem and select “Command Prompt (Admin)”.
rem Written by Yang Zhang Tue Jan 30 14:18:14 2018
rem     Soochow University, China



bcdedit -set LOADOPTIONS DISABLE_INTEGRITY_CHECKS

bcdedit /set testsigning on