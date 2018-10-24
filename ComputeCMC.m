%   Calcola i valori della curva CMC.
function [ output ] = ComputeCMC( input_args )

    indexes =   input_args;
    cmc     =   zeros(1, size(indexes,1));
    
    probesIndexes   =   zeros(1, size(indexes,2));
    for i = 1 : size(indexes,2)
        probesIndexes(1,i) = i;
    end    
    
    
    for i = 1 : size(indexes,1)
        
        rank    =   1;
        result  =   1;
        
        for j = 1 : size(indexes,2)  
            
            if( indexes(i,j) == probesIndexes(1,i))
                rank = result;
            else
                result = result+1;
            end
        end
        
         for j = rank : size(cmc, 2)
             cmc(1,j) =   cmc(1,j) + 1;
         end
        
    end
    
    normalize = cast(size(probesIndexes,2),'double');
    
    cmc = cast(cmc,'double') /  normalize;

    output = cmc; 
end

