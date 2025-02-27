function [simulationResults] = simulatePF(scenarioFunctionHandle, simulationType,ValA,ValB, varargin)
%SIMULATE entry point of the simulation
% This function should be executed to start a simulation. It sets the
% parameters specified in the given scenario file and runs the simulation
% according to the given simulationType.
%
% input:
%   scenarioFunctionHandle: []handle to the scenario file used (e.g. @scenarios.basicScenario)
%   simulationType:         [1x1]enum parameters.setting.SimulationType
%
% output:
%   simulationResults:  [1x1]handleObject simulation.results.ResultsSuperclass
%
% initial author: Lukas Nagel
%
% see also simulationLauncher, parameters.setting.SimulationType,
% simulation.LocalSimulation, simulation.ParallelSimulation,
% simulation.results

the_date = date;
fprintf('Vienna 5G System Level Simulator\n');
fprintf('(c) 2018-%s, Institute of Telecommunications (ITC), TU Wien\n',the_date((end-3):end));
fprintf('This work has been funded by the Christian Doppler Laboratory for Dependable Wireless Connectivity for the Society in Motion.\n\n');
fprintf('By using this simulator, you agree to the license terms stated in the license agreement included with this work.\n\n');

% create Parameters object
params = parameters.Parameters();

%   MODDED!
params = params.setValue(ValA,ValB);
%disp(params)

% set scenario parameters
params = scenarioFunctionHandle(params);

% set dependent parameters
params.setDependentParameters();

% set parameter overrides (useful for comparisons)
if ~isempty(varargin)
    nOverride = size(varargin{:}, 1);

    for oo=1:nOverride
        switch varargin{1}{oo, 1}
            case 'mapValue'
                tempMap = params.(varargin{1}{oo, 2}); %get map to modify
                tempStruct = tempMap(varargin{1}{oo, 3}); %use map key
                tempStruct.(varargin{1}{oo, 4}) = varargin{1}{oo, 5}; %modify selected property/value
                params.(varargin{1}{oo, 2})(varargin{1}{oo, 3}) = tempStruct; %write back modified map       %end

            case 'elementProperty'
                params.(varargin{1}{oo, 2}).(varargin{1}{oo, 3}) = varargin{1}{oo,4};
        end
    end
end

% start simulation
switch simulationType
    case parameters.setting.SimulationType.local

        % create simulation object
        localSimulation = simulation.LocalSimulation(params);

        % set up simulation and generate network elements
        localSimulation.setup;

        % main simulation loop
        localSimulation.run;

        % get results
        simulationResults = localSimulation.simulationResult;

    case parameters.setting.SimulationType.parallel

        %create simulation object
        parallelSimulation = simulation.ParallelSimulation(params);

        % run simulation
        parallelSimulation.setup();
        parallelSimulation.run();

        % get results
        simulationResults = parallelSimulation.simulationResult;

    otherwise
        error('Please see parameters.setting.SimulationType for possible simulation types.');
end
end

