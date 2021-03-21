% Copyright 2014 - 2016 The MathWorks, Inc.
%% loadRobotParameters.m
% This MATLAB script populates the workspace with parameters related to the
% simulation of the Mars rover robot. It specifies plant model parameters to
% characterise the motors and motion of the Mars rover robot.

do_one_run = true; % TRUE for competition (robot stop when all targets are done)
                    % FALSE for demo (robot run forever, start again with
                    %   first target when last one is done)

%% Robot Geometry
AxleLength = 16.7; %Distance between centre-line of driving wheels is 162mm [cm]
WheelRadius = 7/2 ; %Driving wheel diameter is 70mm [cm]

%% Initial Conditions for Robot Position
theta0 = 0; %Initial Robot Angle relative to positive x-axis [deg]
%startPos = single([150 100]); % [cm] %simplifies stateflow if declared single here, but requires cast to double in integrator
startPos = single([150 150]); 
%% Plant Model Motor Parameters:
EncR_init = 0;          %Right encoder initialisation value [deg]
EncL_init = 0;          %Left encoder initialisation value [deg]
EncRes = 636;           %Encoder resolution 636
TauMotor = 0.1;         %Motor time constant


slip_intensity = 0.001; % Estimated slip intensity

%% Plant motor characteristics
motorX = [-100.000000 -90.000000 -70.000000 -50.000000 -30.000000 -27.000000 27.000000 30.000000 50.000000 70.000000 90.000000 100.000000 ];
motorL = [-967.207000 -900.359000 -783.375000 -618.344000 -325.884000 -0.000000 0.000000 325.884000 618.344000 783.375000 900.359000 967.207000 ];
motorR = [-937.961000 -850.223000 -768.752000 -618.344000 -302.905000 -0.000000 0.000000 302.905000 618.344000 768.752000 850.223000 937.961000 ];

motorDeadBand = 30;

%% Camera characteristics
pcam = [24, 100]; % pcam depth of the field of view [cm]
lcam = [21, 90];  % width of the field of view [cm]

%% Distance sensor characteristics
sensor_distance =   [85  80  75  70  65  60  55  50  45  40  35  30  25  20  15  10  5];
sensor_value =      [132 136 144 151 156 162 173 190 210 225 256 275 321 393 504 715 965];
AngularSpeed = 300;

%% Simulation Parameters
Ts = 0.1;  % Step size for model

%% Default Sites Positions
Sites;

%% Controller parameters
cutoffDerivative = 0.3; % cutoff frequency for filtered derivative
xiLowPass = 0.707; % damping (for 2nd order low pass filter)
filteredDerivativeContinuous = tf([1 0],[1/(2*pi*cutoffDerivative)^2 2*xiLowPass/(2*pi*cutoffDerivative) 1]); % tf([1 0],[1/(2*pi*cutoffDerivative) 1])
filteredDerivativeDiscrete = c2d(filteredDerivativeContinuous,Ts,'foh');
[Nfd,Dfd] = tfdata(filteredDerivativeDiscrete,'v');
clear filteredDerivativeDiscrete filteredDerivativeContinuous ...
    xiLowPass cutoffDerivative;

tauLowPassAngleRef = 0.3;
LowPassAngleRef = tf(1,[tauLowPassAngleRef 1]);
LowPassAngleRef = c2d(LowPassAngleRef,Ts,'foh');
[Nlp,Dlp] = tfdata(LowPassAngleRef,'v');

%% Bus definition
bus_Command = Simulink.Bus;
bus_Command.Description = '';
bus_Command.DataScope = 'Auto';
bus_Command.HeaderFile = '';
bus_Command.Alignment = -1;
bus_Command.Elements(1, 1) = Simulink.BusElement;
bus_Command.Elements(1, 1).Name = 'Mode';
bus_Command.Elements(1, 1).Dimensions = 1;
bus_Command.Elements(1, 1).DataType = 'Enum: EMode';
bus_Command.Elements(2, 1) = Simulink.BusElement;
bus_Command.Elements(2, 1).Name = 'Angle';
bus_Command.Elements(2, 1).Dimensions = 1;
bus_Command.Elements(2, 1).DataType = 'single';
bus_Command.Elements(3, 1) = Simulink.BusElement;
bus_Command.Elements(3, 1).Name = 'Position';
bus_Command.Elements(3, 1).Dimensions = 1;
bus_Command.Elements(3, 1).DataType = 'single';

bus_RemainingPosition = Simulink.Bus;
bus_RemainingPosition.Elements = Simulink.BusElement;
bus_RemainingPosition.Elements(1, 1).Name = 'Angle';
bus_RemainingPosition.Elements(1, 1).Dimensions = 1;
bus_RemainingPosition.Elements(1, 1).DataType = 'single';
bus_RemainingPosition.Elements(2, 1) = Simulink.BusElement;
bus_RemainingPosition.Elements(2, 1).Name = 'Distance';
bus_RemainingPosition.Elements(2, 1).Dimensions = 1;
bus_RemainingPosition.Elements(2, 1).DataType = 'single';

bus_Robot = Simulink.Bus;
bus_Robot.Elements(1, 1) = Simulink.BusElement;
bus_Robot.Elements(1, 1).Name = 'EncodersCount';
bus_Robot.Elements(1, 1).Dimensions = 2;
bus_Robot.Elements(1, 1).DataType = 'int32';
bus_Robot.Elements(2, 1) = Simulink.BusElement;
bus_Robot.Elements(2, 1).Name = 'Distance';
bus_Robot.Elements(2, 1).Dimensions = 6;
bus_Robot.Elements(2, 1).DataType = 'int16';
bus_Robot.Elements(3, 1) = Simulink.BusElement;
bus_Robot.Elements(3, 1).Name = 'Bearing';
bus_Robot.Elements(3, 1).Dimensions = 6;
bus_Robot.Elements(3, 1).DataType = 'int8';
bus_Robot.Elements(4, 1) = Simulink.BusElement;
bus_Robot.Elements(4, 1).Name = 'ScannerStatus';
bus_Robot.Elements(4, 1).Dimensions = 1;
bus_Robot.Elements(4, 1).DataType = 'Enum: EPosition';
bus_Robot.Elements(5, 1) = Simulink.BusElement;
bus_Robot.Elements(5, 1).Name = 'ScannerValues';
bus_Robot.Elements(5, 1).Dimensions = [1 3];
bus_Robot.Elements(5, 1).DataType = 'int8';
bus_Robot.Elements(6, 1) = Simulink.BusElement;
bus_Robot.Elements(6, 1).Name = 'Remaining';
bus_Robot.Elements(6, 1).Dimensions = 1;
bus_Robot.Elements(6, 1).DataType = 'Bus: bus_RemainingPosition';

%% Cyborg Parameters

% Strategy Parameters

WAIT_TIME=4;

RADIUS_TARGET=5;
DISTANCE_APPROACH=45;
DISTANCE_PARKING=10;
DISTANCE_MAX=200;

SPEED_NORMAL=30;
SPEED_APPROACH=15;
% Only in exploring mode, to retune 
SPEED_BACK=5; 
S_ROT=10; 
TH1=5; 
TH2=15;
%Regulator params
DEADBAND_DISTANCE = 5;

%% Error Model parameter
% Determinist errors
AXLE_LENGTH_ERR=0.02;
WL_ERR=0.02;
WD_ERR=0.02;
%AXLE_LENGTH_ERR=0.02;
%WL_ERR=0.02;
%WD_ERR=0.02;
% Random errors
ERR_VAR_SENSOR=5; % IR sensor follows Normal Law , to be used un "arm_distance"
VAR_ERR_ENCODER=25*25; % random error du to encoder (random slipping, 

