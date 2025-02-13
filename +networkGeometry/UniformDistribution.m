classdef UniformDistribution < networkGeometry.NodeDistribution
    %UNIFORMDISTRIBUTION homogenous poisson point distribution of network elements
    % Creates the positions of network elements in the given ROI according
    % to a homogenous poisson point process. This means that the number of
    % points to be distrubuted is a Poisson random variable with the
    % parameter lambda being the product of the given density and the area
    % of the ROI. This number of points is then uniformly distributed in
    % the ROI. It is also possible to set the number of points to
    % distribute in the GridParameters struct.
    %
    % initial author: Agnes Fastenbauer
    %
    % modification author: Getúlio Martins Resende
    %
    % see also networkGeometry.NodeDistribution

    properties
        % number of elements to be uniformly distributed in the ROI
        % [1x1]integer number of network elements to be distributed
        nElements
    end

    methods
        function obj = UniformDistribution(placementRegion, GridParameters)
            % class constructor for uniform distribution
            %
            %   placementRegion:	[1x1]handleObject parameters.RegionOfInterest.Region
            %   GridParameter:      [1x1]handleObject parameters.baseSation.Poisson2D or parameters.user.Poisson2D
            %                       can also be a parameters.user.ClusterSuperclass

            % call superclass constructor
            obj = obj@networkGeometry.NodeDistribution(placementRegion);

            % set dependent variables
            obj.setArea;

            % set number of elements
            if GridParameters.density ~= 0 && GridParameters.nElements == 0
                obj.nElements = obj.getNumberOfElements(GridParameters.density);
            elseif GridParameters.nElements ~= 0 && GridParameters.density == 0
                obj.nElements = GridParameters.nElements;
            else
                error('error:missingSettings', 'Please set a density or fixed number of elements.');
            end
        end

        function Locations = getLocations(obj)
            % returns a matrix with uniformly distributed locations in the given region
            % The number of network elements distributed is determined
            % through a poisson distributed random number with density as
            % mean parameter. This number of network elements is then
            % uniformly distributed in the region.
            %
            % output:
            %   Locations:  [1x1]struct with location
            %       -locationMatrix: [2 x nNetworkElements]double locations of network elements
            %                   locationMatrix(1, :) are the x-coordinates
            %                   locationMatrix(2, :) are the y-ccordinates

            % create coordinates
            % MODDED!
            rng(2024);
            xCoordinateArray = obj.xSpan * rand([1, obj.nElements]) + obj.coord2zeroCenter(1);
            yCoordinateArray = obj.ySpan * rand([1, obj.nElements]) + obj.coord2zeroCenter(2);

            % set output struct
            Locations.locationMatrix = [xCoordinateArray; yCoordinateArray];
        end
    end
end

