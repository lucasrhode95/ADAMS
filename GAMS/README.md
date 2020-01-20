ADAMS expects your machine to have a working copy of GAMS and it has to be in your environment variables. That's because ADAMS does NOT implement its own solver, rather, it makes a system call using [**gams "random-name.gms" gdx="another-random-name.gdx"**].

**GAMS and MATLAB must be in the same architecture (x64 ou x32)**

## Setting up GAMS

I've been told that the new versions have an option to automatically add itself to the environment variables, but I'm not sure about that. Anyway, GAMS needs to be in your environment variables:

1. Search for "system variables" in Start menu and hit enter
![Screenshot of Start menu and System properties](../ADAMS_en/figures/ss3.png)

1. After clicking on **Enviroment variables**, select **Path** either from your *User variables* or from your *System variables* and click **Edit**. Now click **Browse** and select the folder where *gams.exe* is located.
![Screenshot of environment variables and Path variable](../ADAMS_en/figures/ss4.png)

1. Done.

## Debugging
To test if it worked, open your command line (search for cmd on Start) and type "gams". Your license information should be displayed.
![Screenshot command prompt](../ADAMS_en/figures/ss5.png)

A common error is to forget to activate GAMS with a working license - which is very hard to detect since it doesn't issue any warnings, it just keeps shooting out empty results - so make sure you license is working fine.
