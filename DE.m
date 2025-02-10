%% Parameters
clear
tic

popSize = 9;        % Population size
maxGenerations = 8; % Maximum number of generations
F = 0.8;            % Differential weight. Default value = 0.8
CR = 0.9;           % Crossover probability. Default value = 0.9
ValMin = 0;         % Minimum bound for ValA and ValB
ValMax = 1;         % Maximum bound for ValA and ValB

usr = 4*30;         % Number of users in the scenario

%% Type of population disposition
typePop = 0; % 0 => random; 1 => equidistant disposition

% Choose the population disposition
if typePop == 0
    % Initialize population (ValA and ValB)
    population = rand(popSize, 2);          % Random values between 0 and 1
elseif typePop == 1
    % Initialize population (ValA and ValB)
    population = linspace(0, 1, popSize);   % Equidistant values between 0 and 1
    population = [population', population'];% Create two columns for ValA and ValB
else
    fprintf('Wrong input\n');
end

% Alpha and Beta values
% Aramide, Samuel O. Et. Al best value
population(1, :) = [0.6, 0.7];
% PF
population(2, :) = [1, 1];

%% Evolutionary loop
% Fitness
bestFitnessOverGen = zeros(1, maxGenerations);
worstFitnessOverGen = zeros(1, maxGenerations);
aveFitnessOverGen = zeros(1, maxGenerations);
stdFitnessOverGen = zeros(1, maxGenerations);

% Throughput
bestThroughputOverGen = zeros(1, maxGenerations); 
worstThroughputOverGen = zeros(1, maxGenerations);
aveThroughputOverGen = zeros(1, maxGenerations);
stdThroughputOverGen = zeros(1, maxGenerations);

% Fairness
bestFairnessOverGen = zeros(1, maxGenerations); 
worstFairnessOverGen = zeros(1, maxGenerations);
aveFairnessOverGen = zeros(1, maxGenerations);
stdFairnessOverGen = zeros(1, maxGenerations);

bestIndividualIdxOverGen = zeros(1, maxGenerations);    % To track best individual
bestIndividualGenesOverGen = zeros(maxGenerations, 2);  % To track best individual's genes

% Initialize arrays to store fitness values for each individual
jainFairnessHistory = zeros(maxGenerations, popSize);
uFitnessHistory = zeros(maxGenerations, popSize);

popOverGenx = zeros(maxGenerations, popSize); % Store A of the population over the generations
popOverGeny = zeros(maxGenerations, popSize); % Store B of the population over the generations

%% Check and delete any existing parallel pool
if ~isempty(gcp('nocreate'))
    delete(gcp('nocreate')); % Delete existing parallel pool
end

% Start parallel pool
parpool; % Start a parallel pool with default settings

%% DE Loop
for gen = 1:maxGenerations
    newPopulation = population;  % Prepare new population
    
    % Initialize arrays to store fitness, throughput, and fairness for the current generation
    fitnessValues = zeros(1, popSize);
    uFitness = zeros(1, popSize);
    jainFairness = zeros(1, popSize);

    if gen == 1
        [~, paperU, paperJain] = computeFitness(population(1, 1), population(1, 2), usr);
        [~, pfU, pfJain] = computeFitness(population(1, 1), population(1, 2), usr);
    end

    parfor i = 1:popSize
        % Mutation: Select 3 distinct individuals
        indices = randperm(popSize, 3);
        x1 = population(indices(1), :);
        x2 = population(indices(2), :);
        x3 = population(indices(3), :);
        
        % Create mutant vector
        mutant = x1 + F * (x2 - x3);
        mutant = min(max(mutant, ValMin), ValMax);  % Ensure within bounds
        
        % Crossover
        crossPoints = rand(1, 2) < CR;
        trial = population(i, :);
        trial(crossPoints) = mutant(crossPoints);
        
        % Selection
        [trialFitnessValue, trialU, trialJain] = computeFitness(trial(1), trial(2), usr);
        [populationFitnessValue, popU, popJain] = computeFitness(population(i, 1), population(i, 2), usr);

        if trialFitnessValue > populationFitnessValue
            newPopulation(i, :) = trial;
            uFitnessHistory(gen, i) = trialU;           % Store uFitness
            jainFairnessHistory(gen, i) = trialJain;    % Store jainFairness
            fitnessValues(i) = trialFitnessValue;       % Store fitness value for later use
            uFitness(i) = trialU;                       % Store throughput for later use
            jainFairness(i) = trialJain;                % Store fairness for later use
        else
            uFitnessHistory(gen, i) = popU;             % Store uFitness
            jainFairnessHistory(gen, i) = popJain;      % Store jainFairness
            fitnessValues(i) = populationFitnessValue;  % Store fitness value for later use
            uFitness(i) = popU;                         % Store throughput for later use
            jainFairness(i) = popJain;                  % Store fairness for later use
        end
    end
    
    % Update population
    population = newPopulation;

    % Store the value of A and B of population in the new variables
    popOverGenx(gen, :) = population(:, 1)';
    popOverGeny(gen, :) = population(:, 2)';
    
    % Now we can use the stored fitness, throughput, and fairness values for current generation
    [bestFitnessOverGen(gen), bestIdx] = max(fitnessValues);        % Find best fitness and index
    bestIndividualIdxOverGen(gen) = bestIdx;                        % Track index of the best individual
    bestIndividualGenesOverGen(gen, :) = population(bestIdx, :);    % Store best individual's genes

    worstFitnessOverGen(gen) = min(fitnessValues);
    aveFitnessOverGen(gen) = mean(fitnessValues);
    stdFitnessOverGen(gen) = std(fitnessValues);

    bestThroughputOverGen(gen) = max(uFitness);  
    worstThroughputOverGen(gen) = min(uFitness);
    aveThroughputOverGen(gen) = mean(uFitness);
    stdThroughputOverGen(gen) = std(uFitness);   

    bestFairnessOverGen(gen) = max(jainFairness);  
    worstFairnessOverGen(gen) = min(jainFairness);
    aveFairnessOverGen(gen) = mean(jainFairness);
    stdFairnessOverGen(gen) = std(jainFairness);
end

%% Print the genes of the best individual of the last generation
% Shut down parallel pool

[known] = knownSched(usr,paperJain,paperU,pfJain,pfU);

delete(gcp('nocreate')); % Delete the parallel pool to release resources

bestIdxLastGen = bestIndividualIdxOverGen(end);
fprintf('Best individual found in the last generation: ValA, ValB = %.4f, %.4f\n', population(bestIdxLastGen, 1), population(bestIdxLastGen, 2));
symTime = toc   % Calculate the algorithm's execution time

%% Plot results
% Plot the fitness along the generations of the DE algorithm
figure;
plot(1:maxGenerations, bestFitnessOverGen, '-r', 'DisplayName', 'Best Fitness');
hold on;
plot(1:maxGenerations, worstFitnessOverGen, '-b', 'DisplayName', 'Worst Fitness');
plot(1:maxGenerations, aveFitnessOverGen, '-g', 'DisplayName', 'Average Fitness');
xlabel('Generations');
ylabel('Fitness');
legend show;
title('Fitness Evolution over Generations');
hold off;

% Plot the mean throughput of the generation over the generations
figure;
plot(1:maxGenerations, bestThroughputOverGen, '-r', 'DisplayName', 'Best Throughput');
hold on;
plot(1:maxGenerations, worstThroughputOverGen, '-b', 'DisplayName', 'Worst Throughput');
plot(1:maxGenerations, aveThroughputOverGen, '-g', 'DisplayName', 'Average Throughput');
xlabel('Generations');
ylabel('Throughput');
legend show;
title('Throughput Evolution over Generations');
hold off;

% Plot the fairness of the generation over the generations
figure;
plot(1:maxGenerations, bestFairnessOverGen, '-r', 'DisplayName', 'Best Fainess');
hold on;
plot(1:maxGenerations, worstFairnessOverGen, '-b', 'DisplayName', 'Worst Fainess');
plot(1:maxGenerations, aveFairnessOverGen, '-g', 'DisplayName', 'Average Fainess');
ylim([0 1])
xlabel('Generations');
ylabel('Fainess');
legend show;
title('Fainess Evolution over Generations');
hold off;

% Create a scatter plot
figure;
hold on;
colors = lines(maxGenerations); % Generate a set of colors for each generation

for gen = 1:maxGenerations
    scatter(jainFairnessHistory(gen, :), uFitnessHistory(gen, :), 50, colors(gen, :), 'filled', 'DisplayName', sprintf('Generation %d', gen));
end

scatter(known(1,1), known(1,2), 50, [0.4940 0.1840 0.5560],'pentagram', 'DisplayName', sprintf('Paper')); % Purple
scatter(known(2,1), known(2,2), 50, [0.4940 0.1840 0.5560],'hexagram', 'DisplayName', sprintf('Pf')); % Purple
scatter(known(3,1), known(3,2), 50, [0.4940 0.1840 0.5560],'x','DisplayName', sprintf('Round Robin'));    % Purple
scatter(known(4,1), known(4,2), 50, [0.4940 0.1840 0.5560],"*", 'DisplayName', sprintf('BestCQI'));       % Purple

xlabel('Jain Fairness');
ylabel('uFitness');
title('uFitness vs Jain Fairness for Each Individual');
legend('Location', 'best');  
grid on;
hold off;

% Create a scatter plot (A x B)
figure;
hold on;
colors = lines(maxGenerations); % Generate a set of colors for each generation

for gen = 1:maxGenerations
    scatter(popOverGenx(gen, :), popOverGeny(gen, :), 50, colors(gen, :), 'filled', 'DisplayName', sprintf('Generation %d', gen));
end

xlabel('A');
ylabel('B');
title('A vs B for Each Individual');
legend('Location', 'best');  
grid on;
hold off;

%% Fitness function
function [fitnessValue, uFitness, jainFairness] = computeFitness(ValA, ValB,dens)
    result0 = simulate(@(params)scenarios.mod3.HetNetDE(params, ValA, ValB,dens), parameters.setting.SimulationType.local);
    Throughput = (mean(result0.userThroughputMBitPerSec.DL, 2, 'omitnan')); % Calculate throughput
    uFitness = mean(Throughput);                                            % Calculate fitness of trial vector
    jainFairness = tools.jainFairness(result0);

    % Bell curve, 1 sigma at 0.7
    fitnessValue = uFitness*(1 / (0.3 * sqrt(2 * pi))) * exp(-((jainFairness - 1).^2) / (2 * 0.3^2));
end

%% Known schedulers
function [resultArray] = knownSched(dens,paperJain,paperU,pfJain,pfU)

    result3 = simulate(@(params)scenarios.mod3.HetNetDE(params, 2, 2,dens), parameters.setting.SimulationType.local);
    result4 = simulate(@(params)scenarios.mod3.HetNetDE(params, 3, 3,dens), parameters.setting.SimulationType.local);

    uFitness3 = mean((mean(result3.userThroughputMBitPerSec.DL, 2, 'omitnan')));
    uFitness4 = mean((mean(result4.userThroughputMBitPerSec.DL, 2, 'omitnan')));
    
    jainFairness3 = tools.jainFairness(result3);
    jainFairness4 = tools.jainFairness(result4);
    

    resultArray = [paperJain,paperU; 
                   pfJain,pfU; 
                   jainFairness3,uFitness3;
                   jainFairness4,uFitness4];
end