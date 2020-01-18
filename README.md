# ADAMS - A Day Ahead Microgrid Simulator
ADAMS is an app built with MATLAB and GAMS that allows the user to create microgrid simulations of a day-ahead planning. It is a result of an undergrad thesis about microgrids presented to the State University of Western Parana (UNIOESTE) on Dec/2019.

# Context
The application consists of a graphical interface meant to configure and run simulations of the optimization strategy called “day-ahead planning”. In this strategy, the main controller schedules the set-points of all the devices on the microgrid (MG) for, typically, 24-hour horizons. The execution of the day-ahead optimization algorithm means choosing the right combo of generators (and/or batteries) that will deliver the energy needed at the lowest possible cost.

# What does ADAMS do
ADAMS actually uses a third-party software to solve the optimisation problem: [GAMS](https://www.gams.com/products/introduction/). What ADAMS does is it provides an interface so that the user doesn't need to worry about mathematical modeling in GAMS (which can be intimidating).

The workflow is as follows:
1. The user sets up the simulation, choosing from a list of available MG elements (diesel generators, solar panels, loads etc.)
2. ADAMS dynamically generates a GAMS file and sends it to that software
3. GAMS returns the data and ADAMS display the results