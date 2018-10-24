classdef Bag < handle
       
    properties
        
        Patches             = cell(1,1);             
        Rectangle           ;      %   Vettore contenente X_0 Y_0 X_width Y_height
        
        %   Utilizzati dal metodo CreateSimulatedPatches.
        BagOriginalSize     = 0;        
        SourceIdentities    ;      %   Vettore
    
    end
    
    methods
            
        function output = Size(obj)
            
               output  =   size( obj.Patches, 2); 
        
        end
        
    end
    
end

