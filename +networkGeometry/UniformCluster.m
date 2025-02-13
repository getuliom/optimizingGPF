classdef UniformCluster < networkGeometry.ClusteredDistribution
    %UNIFORMCLUSTER cluster distribution with Matern Cluster Process
    % Creates a clustered distribution of points where the clusters are
    % created with a homogenous poisson point process in the
    % ClusteredDistribution class. Within the cluster the network elements
    % are uniformaly distributed for round or rectangular regions. The
    % number of points in each cluster can be set to a fixed value or is
    % calculated through a poisson random variable with the set density
    % (homogenous poisson point process within cluster).
    %
    % initial author: Agnes Fastenbauer
    %
    % modification author: Getúlio Martins Resende
    %
    % see also networkGeometry.NodeDistribution,
    % networkGeometry.ClusteredDistribution, networkGeometry.GaussCluster

    methods
        function obj = UniformCluster(placementRegion, GridParameters)
            % class constructor for UniformCluster
            % The clusterDensity is set in the superclass.
            %
            % input:
            %   placementRegion:	[1x1]handleObject parameters.RegionOfInterest.Region
            %   GridParameters:     [1x1]handleObject parameters.user.UniformCluster
            %
            % calls superclass constructor

            % call superclass constructor
            obj = obj@networkGeometry.ClusteredDistribution(placementRegion, GridParameters);
        end

        function clusterLocations = getClusterLocations(obj)
            % creates locations of cluster network elements
            %
            % used properties: nClusterElements, clusterCentres,
            % clusterShape, cluster2zero
            %
            % output:
            %   clusterLocations:   [2 x totalClusterElements]double
            %                       [x;y] cartesian coordinates of cluster
            %                       elements

            % initialize cluster locations array
            clusterLocations = zeros(2, sum(obj.nClusterElements));

            % initialize element count
            iElement = 0;

            % create locations for each cluster
            for iCluster = 1:size(obj.clusterCentres, 2)
                % create first and second coordinates: radius and angle for
                % round clusters, x and y coordinates for rectangular
                % clusters
                % MODDED!
                rng(2024)
                firstCoordinateArray = obj.clusterSize1 * rand([1, obj.nClusterElements(iCluster)]);
                secondCoordinateArray = obj.clusterSize2 * rand([1, obj.nClusterElements(iCluster)]);

                % transform polar to cartesian coordinates for round clusters
                if strcmp(obj.clusterShape, 'round')
                    [firstCoordinateArray, secondCoordinateArray] = pol2cart(secondCoordinateArray, firstCoordinateArray);
                end

                % Shift cluster coordinates to center them around the
                % cluster center
                firstCoordinateArray = firstCoordinateArray + obj.clusterCentres(1, iCluster) - obj.cluster2zero(1);
                secondCoordinateArray = secondCoordinateArray + obj.clusterCentres(2, iCluster) - obj.cluster2zero(2);

                % write elements in clusterLocations array
                clusterLocations(:, (iElement + 1):(iElement + obj.nClusterElements(iCluster))) = [firstCoordinateArray; secondCoordinateArray];

                % increment cluster element count
                iElement = iElement + obj.nClusterElements(iCluster);
            end % for all clusters
        end
    end
end

