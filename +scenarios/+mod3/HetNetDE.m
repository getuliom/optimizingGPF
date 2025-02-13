function params = HetNetDE(params,a,b,usr)
% heterogeneous scenario consisting of various base station and user types
% Macro, pico, and femto base stations and pedestrian and car users are
% placed in the simulation region. The femto cells are favored for cell
% association and NOMA is used for transmission. The macroscopic fading
% models are set individually for each link type. Indoor and LOS decisions
% for links are set per user type and PDP channel models are used for
% pedestrian and vehicular users and an AWGN channel is assumed for users
% in clusters around femto base stations. A weighted round robin scheduler
% favors vehicular users for scheduling.
%
% initial author: Fjolla Ademaj
%
% modification author: Getúlio Martins Resende
%
% see also launcherFiles.launcherHetNet

%% General Configuration
% time config
params.time.slotsPerChunk = 100;    % Default 10; set:100
params.time.feedbackDelay = 1;      % small feedback delay

% set NOMA parameters
params.noma.mustIdx                 = parameters.setting.MUSTIdx.Idx01;
params.noma.interferenceFactorSic	= 0; % no error propagation
params.noma.deltaPairdB             = 7;
% perform NOMA transmssion even if far user CQI is low - this will increase the number of failed transmissions
params.noma.abortLowCqi             = true;

% define the region of interest
params.regionOfInterest.xSpan = 300;
params.regionOfInterest.ySpan = 300;

% set carrier frequency and bandwidth
params.carrierDL.centerFrequencyGHz             = 2;    % in GHz
params.transmissionParameters.DL.bandwidthHz    = 10e6; % in Hz Default = 10e6

% associate users to cell with strongest receive power - favor femto cell association
params.cellAssociationStrategy                      = parameters.setting.CellAssociationStrategy.maxReceivePower;
params.pathlossModelContainer.cellAssociationBiasdB = [0, 0, 5];

% additional object that should be saved into simulation results
params.save.losMapUEAnt     = true;
params.save.isIndoor        = true;

%% Scheduler
if (a == 2) && (b == 2)
    % use Round Robin scheduler
    params.schedulerParameters.type = parameters.setting.SchedulerType.roundRobin;
elseif (a == 3) && (b == 3)
    % use best CQI scheduler
    params.schedulerParameters.type = parameters.setting.SchedulerType.bestCqi;
else
        %   Maximize Throughput: a=1, b=0
        %   Proportional Fair:   a=1, b=1
        %   Max Min Fair:        a=0, b=1

    % Minimal Configuration (3.5.8)
    params.schedulerParameters.type = parameters.setting.SchedulerType.multiUser;
    params.transmissionParameters.DL.feedbackType = parameters.setting.FeedbackType.muMIMO;
 

    params.schedulerParameters.groupingParameters.userGrouping = parameters.setting.SchedulerUserGrouping.SPRS; % example value
    params.schedulerParameters.groupingParameters.sprsMaxCorrelation = 0.9;                                     % default value
    params.schedulerParameters.groupingParameters.sprsSkipProbability = 0.9;                                    % default value
    params.schedulerParameters.groupingParameters.spsrFactorA = a;                                              % default value
    params.schedulerParameters.groupingParameters.sprsFactorB = b;                                              % default value
end
%% pathloss model container
indoor	= parameters.setting.Indoor.indoor;
outdoor	= parameters.setting.Indoor.outdoor;
LOS     = parameters.setting.Los.LOS;
NLOS	= parameters.setting.Los.NLOS;

% macro base station models
macro = parameters.setting.BaseStationType.macro;
params.pathlossModelContainer.modelMap{macro,	indoor,     LOS}        = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	indoor,     LOS}.isLos  = true;
params.pathlossModelContainer.modelMap{macro,	indoor,     NLOS}       = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	indoor,     NLOS}.isLos = false;
params.pathlossModelContainer.modelMap{macro,	outdoor,	LOS}        = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	outdoor,	LOS}.isLos  = true;
params.pathlossModelContainer.modelMap{macro,	outdoor,	NLOS}       = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	outdoor,	NLOS}.isLos = false;
% pico base station models
pico = parameters.setting.BaseStationType.pico;
params.pathlossModelContainer.modelMap{pico,	indoor,     LOS}    = parameters.pathlossParameters.FreeSpace;
params.pathlossModelContainer.modelMap{pico,	indoor,     NLOS}   = parameters.pathlossParameters.FreeSpace;
params.pathlossModelContainer.modelMap{pico,	outdoor,	LOS}    = parameters.pathlossParameters.FreeSpace;
params.pathlossModelContainer.modelMap{pico,	outdoor,	NLOS}   = parameters.pathlossParameters.FreeSpace;
% femto base station models
femto = parameters.setting.BaseStationType.femto;
params.pathlossModelContainer.modelMap{femto,	indoor,     LOS}    = parameters.pathlossParameters.Indoor;
params.pathlossModelContainer.modelMap{femto,   indoor,     NLOS}   = parameters.pathlossParameters.Indoor;
params.pathlossModelContainer.modelMap{femto,	outdoor,    LOS}    = parameters.pathlossParameters.StreetCanyonLOS;
params.pathlossModelContainer.modelMap{femto,	outdoor,	NLOS}   = parameters.pathlossParameters.StreetCanyonNLOS;

%% Configuration of the Network Elements
% macro base stations
macroBS = parameters.basestation.HexGrid;
macroBS.interBSdistance         = 120;
macroBS.antenna                 = parameters.basestation.antennas.Omnidirectional;
macroBS.antenna.nTX             = 1;
macroBS.antenna.transmitPower   = 40;
macroBS.antenna.baseStationType = parameters.setting.BaseStationType.macro;
macroBS.antenna.height          = 35;
params.baseStationParameters('macro') = macroBS;

% pico base stations along a straight street
posPico = [-145, -75,  0, 75, 145;...
    24,  36, 24, 36,  24];
streetPicoBS = parameters.basestation.PredefinedPositions;
streetPicoBS.positions                  = posPico;
streetPicoBS.antenna                    = parameters.basestation.antennas.Omnidirectional;
streetPicoBS.antenna.nTX                = 1;
streetPicoBS.antenna.height             = 5;
streetPicoBS.antenna.baseStationType    = parameters.setting.BaseStationType.pico;
streetPicoBS.antenna.transmitPower      = 20;
params.baseStationParameters('pico') = streetPicoBS;

% clustered users with femto at cluster center
clusteredUser = parameters.user.UniformCluster;
clusteredUser.nElements         = usr/4;    % number of users placed
clusteredUser.clusterRadius     = 5;
clusteredUser.clusterDensity    = 5e-2;     % density of users in a cluster
clusteredUser.nRX               = 1;
clusteredUser.speed             = 0;        % static user
clusteredUser.movement          = parameters.user.movement.Static;
clusteredUser.schedulingWeight  = 1;        % do not favor this user type
clusteredUser.indoorDecision    = parameters.indoorDecision.Static(parameters.setting.Indoor.indoor);
clusteredUser.losDecision       = parameters.losDecision.StreetCanyon;
clusteredUser.channelModel      = parameters.setting.ChannelModel.Rayleigh;
clusteredUser.withFemto         = true;
clusteredUser.femtoParameters.antenna                   = parameters.basestation.antennas.Omnidirectional;
clusteredUser.femtoParameters.antenna.nTX               = 1;
clusteredUser.femtoParameters.antenna.height            = 1.5;
clusteredUser.femtoParameters.antenna.transmitPower     = 1;
clusteredUser.femtoParameters.antenna.baseStationType   = parameters.setting.BaseStationType.femto;
params.userParameters('clusterUser') = clusteredUser;

% pedestrian users
poissonPedestrians = parameters.user.Poisson2D;
poissonPedestrians.nElements            = usr/4;    % number of users placed
poissonPedestrians.nRX                  = 1;
poissonPedestrians.speed                = 0;        % static user
poissonPedestrians.movement             = parameters.user.movement.Static;
poissonPedestrians.schedulingWeight     = 10;       % assign 10 resource blocks when scheduled
poissonPedestrians.indoorDecision       = parameters.indoorDecision.Random(0.5);
poissonPedestrians.losDecision          = parameters.losDecision.UrbanMacro5G;
poissonPedestrians.channelModel         = parameters.setting.ChannelModel.PedA;
params.userParameters('poissonUserPedestrian') = poissonPedestrians;

% car user distributed through a Poisson point process
poissonCars                     = parameters.user.Poisson2D;
poissonCars.nElements           = usr/4;
poissonCars.nRX                 = 1;
poissonCars.speed               = 50/3.6;
poissonCars.movement            = parameters.user.movement.RandomDirection;
poissonCars.schedulingWeight    = 10; % assign 10 resource blocks when scheduled
poissonCars.indoorDecision      = parameters.indoorDecision.Static(parameters.setting.Indoor.outdoor);
poissonCars.losDecision         = parameters.losDecision.UrbanMacro5G;
poissonCars.channelModel        = parameters.setting.ChannelModel.VehB;
params.userParameters('poissonUserCar') = poissonCars;

% car users on the street served by pico base stations
width_y     = 8;
width_x     = 150;
nUser       = usr/4;
rng(1)
xRandom     =      width_x * rand(1, nUser) - width_x / 2;
yRandom     = 30 + width_y * rand(1, nUser) - width_y / 2;
posUser3    = [xRandom; yRandom; 1.5*ones(1,nUser)];
streetCars = parameters.user.PredefinedPositions;
streetCars.positions            = posUser3;
streetCars.nRX                  = 1;
streetCars.speed                = 100/3.6;
streetCars.movement             = parameters.user.movement.RandomDirection;
streetCars.schedulingWeight     = 10; % assign 10 resource blocks when scheduled
streetCars.indoorDecision       = parameters.indoorDecision.Static(parameters.setting.Indoor.outdoor);
streetCars.losDecision          = parameters.losDecision.Static;
streetCars.losDecision.isLos    = true;
streetCars.channelModel         = parameters.setting.ChannelModel.VehA;
params.userParameters('vehicle') = streetCars;
end

