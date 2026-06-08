function atmosphere = ISA_atmosphere(altitudeGeometric_m, densityScaleFactor)
%ISA_ATMOSPHERE  International Standard Atmosphere model for Gaganyaan descent simulation.
%
%   atmosphere = ISA_atmosphere(altitudeGeometric_m)
%   atmosphere = ISA_atmosphere(altitudeGeometric_m, densityScaleFactor)
%
%   INPUTS
%   altitudeGeometric_m : Geometric altitude above mean sea level [m].
%                         Scalar, vector, or array accepted.
%   densityScaleFactor  : Optional multiplier for atmospheric density [-].
%                         Use this for Monte Carlo density perturbation.
%                         Example: 1.03 gives +3% density.
%
%   OUTPUT
%   atmosphere : struct containing
%       .altitudeGeometric_m
%       .altitudeGeopotential_m
%       .temperature_K
%       .pressure_Pa
%       .density_kg_m3
%       .speedOfSound_mps
%       .dynamicViscosity_Pa_s
%       .kinematicViscosity_m2_s
%       .gravity_mps2
%       .layerIndex
%       .outsideModelRange
%
%   NOTES
%   1. This implementation uses the 1976 ISA layer equations from sea level
%      to 84.852 km geopotential altitude. The parachute recovery phase for
%      Gaganyaan-type simulations occurs below ~17 km, so this covers the
%      current MATLAB descent model with large margin.
%   2. For geometric altitudes above the ISA-1976 lower/middle atmosphere
%      range, the model clamps the thermodynamic state to the top layer and
%      flags outsideModelRange = true. Use a high-altitude atmosphere model
%      such as NRLMSISE-00 for full 120 km re-entry aerothermodynamics.
%   3. SI units are used throughout.
%
%   Author: Ayush Bhatt project support file

    if nargin < 2 || isempty(densityScaleFactor)
        densityScaleFactor = 1.0;
    end

    validateattributes(altitudeGeometric_m, {'numeric'}, {'real'}, ...
        mfilename, 'altitudeGeometric_m', 1);
    validateattributes(densityScaleFactor, {'numeric'}, {'real','positive','scalar'}, ...
        mfilename, 'densityScaleFactor', 2);

    inputSize = size(altitudeGeometric_m);
    altitudeOriginal_m = altitudeGeometric_m;
    altitudeVector_m = altitudeGeometric_m(:);

    % Clamp below sea level to zero for splashdown/ground numerical safety.
    altitudeForModel_m = max(altitudeVector_m, 0);

    % Constants for ISA 1976 lower/middle atmosphere.
    earthRadius_m = 6356766.0;        % ISA geopotential Earth radius [m]
    gravitySeaLevel_mps2 = 9.80665;  % standard gravity [m/s^2]
    gasConstantAir_JpkgK = 287.05287;
    heatCapacityRatio = 1.4;

    % ISA base geopotential heights [m] and lapse rates [K/m].
    baseGeopotentialHeight_m = [0; 11000; 20000; 32000; 47000; 51000; 71000; 84852];
    lapseRate_Kpm = [-0.0065; 0.0; 0.0010; 0.0028; 0.0; -0.0028; -0.0020];

    baseTemperature_K = zeros(size(baseGeopotentialHeight_m));
    basePressure_Pa = zeros(size(baseGeopotentialHeight_m));
    baseTemperature_K(1) = 288.15;
    basePressure_Pa(1) = 101325.0;

    % Build base-state table recursively.
    for layerNumber = 1:numel(lapseRate_Kpm)
        heightStep_m = baseGeopotentialHeight_m(layerNumber + 1) - baseGeopotentialHeight_m(layerNumber);
        currentLapseRate_Kpm = lapseRate_Kpm(layerNumber);
        currentBaseTemperature_K = baseTemperature_K(layerNumber);
        currentBasePressure_Pa = basePressure_Pa(layerNumber);

        if abs(currentLapseRate_Kpm) < eps
            baseTemperature_K(layerNumber + 1) = currentBaseTemperature_K;
            basePressure_Pa(layerNumber + 1) = currentBasePressure_Pa * ...
                exp(-gravitySeaLevel_mps2 * heightStep_m / ...
                (gasConstantAir_JpkgK * currentBaseTemperature_K));
        else
            nextBaseTemperature_K = currentBaseTemperature_K + currentLapseRate_Kpm * heightStep_m;
            baseTemperature_K(layerNumber + 1) = nextBaseTemperature_K;
            basePressure_Pa(layerNumber + 1) = currentBasePressure_Pa * ...
                (currentBaseTemperature_K / nextBaseTemperature_K) ^ ...
                (gravitySeaLevel_mps2 / (gasConstantAir_JpkgK * currentLapseRate_Kpm));
        end
    end

    % Convert geometric altitude to geopotential altitude.
    altitudeGeopotential_m = earthRadius_m .* altitudeForModel_m ./ ...
        (earthRadius_m + altitudeForModel_m);

    maximumModelHeight_m = baseGeopotentialHeight_m(end);
    outsideModelRange = altitudeGeopotential_m > maximumModelHeight_m;
    altitudeGeopotentialClamped_m = min(altitudeGeopotential_m, maximumModelHeight_m);

    temperature_K = zeros(size(altitudeGeopotentialClamped_m));
    pressure_Pa = zeros(size(altitudeGeopotentialClamped_m));
    layerIndex = zeros(size(altitudeGeopotentialClamped_m));

    for sampleIndex = 1:numel(altitudeGeopotentialClamped_m)
        currentHeight_m = altitudeGeopotentialClamped_m(sampleIndex);

        currentLayer = find(currentHeight_m >= baseGeopotentialHeight_m(1:end-1) & ...
            currentHeight_m <= baseGeopotentialHeight_m(2:end), 1, 'last');

        if isempty(currentLayer)
            currentLayer = 1;
        end
        if currentLayer > numel(lapseRate_Kpm)
            currentLayer = numel(lapseRate_Kpm);
        end

        layerIndex(sampleIndex) = currentLayer;

        heightAboveBase_m = currentHeight_m - baseGeopotentialHeight_m(currentLayer);
        currentLapseRate_Kpm = lapseRate_Kpm(currentLayer);
        currentBaseTemperature_K = baseTemperature_K(currentLayer);
        currentBasePressure_Pa = basePressure_Pa(currentLayer);

        if abs(currentLapseRate_Kpm) < eps
            temperature_K(sampleIndex) = currentBaseTemperature_K;
            pressure_Pa(sampleIndex) = currentBasePressure_Pa * ...
                exp(-gravitySeaLevel_mps2 * heightAboveBase_m / ...
                (gasConstantAir_JpkgK * currentBaseTemperature_K));
        else
            temperature_K(sampleIndex) = currentBaseTemperature_K + currentLapseRate_Kpm * heightAboveBase_m;
            pressure_Pa(sampleIndex) = currentBasePressure_Pa * ...
                (currentBaseTemperature_K / temperature_K(sampleIndex)) ^ ...
                (gravitySeaLevel_mps2 / (gasConstantAir_JpkgK * currentLapseRate_Kpm));
        end
    end

    density_kg_m3 = pressure_Pa ./ (gasConstantAir_JpkgK .* temperature_K);
    density_kg_m3 = density_kg_m3 .* densityScaleFactor;

    speedOfSound_mps = sqrt(heatCapacityRatio * gasConstantAir_JpkgK .* temperature_K);

    % Sutherland viscosity model for air.
    sutherlandReferenceTemperature_K = 273.15;
    sutherlandReferenceViscosity_Pa_s = 1.716e-5;
    sutherlandConstant_K = 110.4;
    dynamicViscosity_Pa_s = sutherlandReferenceViscosity_Pa_s .* ...
        (temperature_K ./ sutherlandReferenceTemperature_K).^(3/2) .* ...
        (sutherlandReferenceTemperature_K + sutherlandConstant_K) ./ ...
        (temperature_K + sutherlandConstant_K);

    kinematicViscosity_m2_s = dynamicViscosity_Pa_s ./ density_kg_m3;

    gravity_mps2 = gravitySeaLevel_mps2 .* ...
        (earthRadius_m ./ (earthRadius_m + altitudeForModel_m)).^2;

    atmosphere.altitudeGeometric_m = reshape(altitudeOriginal_m, inputSize);
    atmosphere.altitudeGeopotential_m = reshape(altitudeGeopotential_m, inputSize);
    atmosphere.temperature_K = reshape(temperature_K, inputSize);
    atmosphere.pressure_Pa = reshape(pressure_Pa, inputSize);
    atmosphere.density_kg_m3 = reshape(density_kg_m3, inputSize);
    atmosphere.speedOfSound_mps = reshape(speedOfSound_mps, inputSize);
    atmosphere.dynamicViscosity_Pa_s = reshape(dynamicViscosity_Pa_s, inputSize);
    atmosphere.kinematicViscosity_m2_s = reshape(kinematicViscosity_m2_s, inputSize);
    atmosphere.gravity_mps2 = reshape(gravity_mps2, inputSize);
    atmosphere.layerIndex = reshape(layerIndex, inputSize);
    atmosphere.outsideModelRange = reshape(outsideModelRange, inputSize);
end
