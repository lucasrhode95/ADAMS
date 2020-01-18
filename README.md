![ADAMS splash screen](ADAMS_en/figures/splash.png)
ADAMS is an app built with MATLAB and GAMS that allows the user to create microgrid simulations of a day-ahead planning. It is a result of an undergrad thesis about microgrids presented to the State University of Western Parana (UNIOESTE) on Dec/2019.

# Context
The application consists of a graphical interface meant to configure and run simulations of the optimisation strategy called “day-ahead planning” for microgrids (MGs). In this technique, the main controller of a MG schedules the set-points of all the devices on the MG for, typically, 24-hour horizons. The execution of the day-ahead algorithm means choosing the right combo of generators (and/or batteries) that will deliver the energy needed at the lowest possible cost.

# What does ADAMS do
ADAMS actually uses a third-party software to solve the optimisation problem: [GAMS](https://www.gams.com/products/introduction/). What ADAMS does is provide an interface so that the end-user doesn't need to worry about mathematical modeling in GAMS (which can be intimidating).

The workflow is as follows:
1. The user sets up the simulation in ADAMS, choosing from a list of available MG elements (diesel generators, solar panels, loads etc.)
1. ADAMS dynamically generates a mathematical model and sends it to GAMS
1. GAMS solves the optimisation problem and sends the results back to ADAMS
1. ADAMS display the results in a nice point-and-click kind of way

# Installation

# Screenshots
![Main screen](ADAMS_en/figures/ss1.png)
Main screen of ADAMS

![Main screen](ADAMS_en/figures/ss2.png)
TSChart: a sub-app to visualize time-series
