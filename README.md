# Sommarstugekoll

A remotely (by telephone) controlled domestic automation assistant.

The main function of the system is to inform the user of the current temperatures at the points of measurement, and also to give the user remote binary control (on/off) of a number of external functions. 

These functions could be  for example heating systems, radiators, or lighting.

Information- and control data is exchanged via a standard analog telephone connection, POTS (Plain Old Telephone Service) using DTMF (Dual Tone, Multiple Frequency).

The project is based around two CPLDs and is mainly a VHDL/Digital Logic project,  although it also incorporates other interesting integrated circuits such as sensors. The project is completed and ready to be used, but can be expanded for further functionality, such as extreme temperature alarm, better measuring resolution, outgoing calls or caller authentication.

### Features

* Temperature monitoring 

* Control of external functions, for example heating

* Accessible via a standard telephone connection

* Voice playback for information

### Components Used

* Xilinx X9572XL (CPLD, 2x)

* Mitel MT8880 (DTMF Transceiver)

* Futurlec ISD2560P (Sound Memory Circuit)

* Maxim DS18S20 (Digital Thermometer, 2x)

### Report

The project is described in a technical report, where one can also find circuit diagrams, PCB layout and complete BOM list.
