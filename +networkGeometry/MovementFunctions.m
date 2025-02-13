classdef MovementFunctions
    % collection of user position setting functions modeling user movement
    % The user movement overwrites the initial user position.
    %
    % initial author: Brom Jeanne (moved from networkElements.ue.User)
    %
    % modification author: Getúlio Martins Resende
    %
    % see also parameters.user.movement,
    % simulation.SimulationSetup.createUsers

    methods (Static)
        function setMovementStatic(users, ~, params)
            % set user movement to initial user position
            %
            % input:
            %   users:          [1 x nUser_type]handleObject users with this movement model
            %   userParameters: [1x1]handleObject parameters.user.Parameters
            %   params:         [1x1]handleObject parameters.Parameters

            for uu = 1:length(users)
                users(uu).positionList = repmat(users(uu).positionList(:,1), 1, params.time.nSlotsTotal);
            end

            % move users that have left the ROI back into ROI
            networkGeometry.MovementFunctions.keepUserInRegion(users, params);
        end

        function setMovementRandomDirection(users, userParameters, params)
            % set user to move in a random direction
            %
            % input:
            %   users:          [1 x nUser_type]handleObject users with this movement model
            %   userParameters: [1x1]handleObject parameters.user.Parameters
            %   params:         [1x1]handleObject parameters.Parameters

            % get number of users
            nUser = length(users);

            % set random direction for each user - user height remains constant
            % MODDED!
            rng(1)
            direction = 2*pi*(rand(nUser,1)-.5);
            direction = [sin(direction), cos(direction), zeros(nUser,1)];

            % get offset position matrix of size [nUser x 3 x nSlotsTotal]
            timeSinceStart = reshape(params.timeMatrix(:), 1, 1, params.time.nSlotsTotal);
            offset = direction .* userParameters.speed .* timeSinceStart;

            % set user positions
            for iUser = 1:nUser
                users(iUser).positionList = users(iUser).positionList(:,1) + squeeze(offset(iUser,:,:));
            end

            % move users that have left the ROI back into ROI
            networkGeometry.MovementFunctions.keepUserInRegion(users, params);
        end

        function setMovementRandomWalk(users, userParameters, params)
            % set user to move in a direction randomly chosen in each slot
            %
            % input:
            %   users:          [1 x nUser_type]handleObject users with this movement model
            %   userParameters: [1x1]handleObject parameters.user.Parameters
            %       -movement.correlation:	[1x1]double correlation
            %   params:         [1x1]handleObject parameters.Parameters

            % get number of users
            nUser = length(users);

            % set correlation matrix
            c = userParameters.movement.correlation;
            cM = toeplitz([sqrt(1-c^2),zeros(1,params.time.nSlotsTotal-1)], [sqrt(1-c^2),c,zeros(1,params.time.nSlotsTotal-2)]);
            cM(1) = 1;

            % get random direction for each user and each slot
            direction = 2*pi*(rand(nUser, params.time.nSlotsTotal)-.5) * cM;

            % set user positions
            for iUser = 1:nUser
                direction_ = [sin(direction(iUser,:)); cos(direction(iUser,:)); zeros(1,params.time.nSlotsTotal)];
                Doffset = direction_ * userParameters.speed * params.time.slotDuration;
                offset = cumsum(Doffset,2);
                users(iUser).positionList = users(iUser).positionList(:,1) + offset;
            end

            % move users that have left the ROI back into ROI
            networkGeometry.MovementFunctions.keepUserInRegion(users, params);
        end

        function setMovementPredefined(users, userParameters, params)
            % set user movement to predefined positions
            %
            % input:
            %   users:          [1 x nUser_type]handleObject users with this movement model
            %   userParameters: [1x1]handleObject parameters.user.Parameters
            %       -movement.positionList:	[3 x nSlotsTotal x nUser]double
            %   params:         [1x1]handleObject parameters.Parameters

            for iUser = 1:length(users)
                users(iUser).positionList = userParameters.movement.positionList(:,:,iUser);
            end

            % move users that have left the ROI back into ROI
            networkGeometry.MovementFunctions.keepUserInRegion(users, params);
        end

        function keepUserInRegion(users, params)
            % keeps users in the ROI (or interference region - depending on setting)
            % This function mirrors the positions of the users leaving the
            % simulation region.
            %
            % input:
            %   users:  [1 x nUsers]handleObject networkElements.ue.User
            %   params: [1x1]handleObject parameters.Parameters

            % get placement region -  the region in which the users are allowed to move
            placementRegion = params.regionOfInterest.placementRegion;

            % get number of users
            nUser = length(users);

            % set mirror matrix
            u = [0  1  0 -1    % x-coordinate
                1  0  -1 0     % y-coordinate
                0  0  0  0];   % z-coordinate

            % number of borders of the placement region
            nu = size(u,2);

            % get abolute value of the limits of the placement region in a vector
            b = [placementRegion.yMax;
                placementRegion.xMax;
                -placementRegion.yMin;
                -placementRegion.xMin];

            for iUser = 1:nUser
                % get position array of this user
                p = users(iUser).positionList;

                % flag for users whose positions have mirrored
                % The following loop mirrors all positions after the first
                % user position outside of the placement region. This if a
                % position has been mirrored the loop needs to check again
                % if it has set positions to outside the placement region.
                hasMirrored = true;
                while hasMirrored
                    hasMirrored = false;
                    for i = 1:nu
                        % get absloute value of position to compare with placement region limit
                        pp = u(:,i)' * p;
                        % find positions where this user leaves placement region
                        iMirror = find(pp>b(i),1,'first');
                        if ~isempty(iMirror)
                            % mirror positions at the border of the placement region
                            p(:,iMirror:end) = p(:,iMirror:end) + 2 * u(:,i)*(b(i) - pp(iMirror:end));
                            % set hasMirriored to true to check if all
                            % positions are now in the placement region
                            hasMirrored = true;
                        end % if this user has to be brought back from outside the placement region
                    end % for all region limits - 4 sides of a rectangle (xMIn, xMax, yMin, yMax)
                end

                % set mirrored position array for this user
                users(iUser).positionList = p;
            end % for all users
        end
    end
end

