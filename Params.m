%   Parametri utilizzati dal codice C#

classdef Params < handle
        
    properties
        
        DescCreation_binSizes = [ 24 , 12 , 4 ];
        DescCreation_ColourPatchNr = 80;
        DescCreation_PatchHeight = 0.32;
        DescCreation_PatchWidth = 0.32;
        DescCreation_minpatchCoverage = 0.4;
        DescMatching_kValue = 11;
        
        %   Utilizzato dal metodo CreateSimulatedPatches
        DescCreation_simulVector = [ 1.4 , 1.2 , 1.0 , 0.8 , 0.6 ];
                
    end
       
end

