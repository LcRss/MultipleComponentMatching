classdef Descriptor < handle
       
    properties
        
        Bags                = cell(1,2);           
        HasIdentity         = 0;
        identity            = -1;   
    
    end
    
    methods
        
        %   Utilizzato dal metodo CreateSimulatedPatches.
        function output = GetIdentity(obj)
            output = obj.identity;
        end
        
    end
    
end

