classdef Patch < handle
      
    properties
        
        rect            ;               %   Vettore
        features        ;               %   Vettore
        
        %   Utilizzati dal metodo CreateSimulatedPatches.
        SourceIdentity  ;
        isSimulated     = 0;

        
        
    end
    
    methods
        
        %   Costruttore.
        function obj = Patch(varargin)              
        %   Varargin is an input variable in a function definition statement
        %   that allows the function to accept any number of input arguments.        
                
                obj.isSimulated = 0;
                
                if nargin == 1
                    
                    inputFeature = varargin{1};
                    obj.features = inputFeature;     
                
                end
      
                if nargin == 3
                    
                    inputFeatures = varargin{1};
                    inputRect = varargin{2};
                    inputIsSimulated = varargin{3};
                    
                    obj.features = inputFeatures;
                    obj.rect = inputRect;
                    obj.isSimulated = inputIsSimulated ;
                
                end
        end 
    end    
end

