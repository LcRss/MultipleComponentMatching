# Multiple Component Matching #

### Scopo del repository ###

* Il repository è stato utilizzato per l'implementazione in linguaggio Matlab dell'algoritmo: [Multiple Component Matching ](https://scholar.google.it/scholar?q=a+multiple+component+matching+framework+for+person+re-identification&hl=it&as_sdt=0&as_vis=1&oi=scholart&sa=X&ved=0ahUKEwjIrf_4moTOAhWBnhQKHfCCDaYQgQMIHDAA) per la reidentificatione di persone a breve termine.


### Contenuto ###
Sono presenti 6 classi Matlab:

* Params;
* Bag;
* Patch;
* Descriptor;
* DescriptorBulder;
* DescriptorMatcher.

Una funzione : 

* ComputeCMC.

Uno script:

* Program.

### Dipendenze ###
La classe DescriptorBuider utilizza le classi Params, Bag, e Patch per la creazione di una variabile Descriptor per ogni immagine.

La classe DecriptorMatcher confronta le variabili descriptor.

Lo script Program utilizza le classi DescriptorBuilder e DescriptorMatcher per effettuare i confronti sulle immagini appartenenti al dataset fornito in ingresso.

### Test ###
Il codice è stato testato fornendo in ingresso il VIPeR dataset con le relative maschere.

Al fine di svolgere altri test, utilizzando il medesimo script Program, è necessario che il dataset fornito sia strutturato in modo tale che per ogni individuo siano presenti due immagini da utilizzare nella creazione di un probe set ed un template, contenenti rispettivamente gli individui da ricercare e le immagini dove cercarli.
Per valutare l'efficienza tramite la Cumulative Matching Characteristics bisogna conoscere la posizione dell'individuo i-esimo, appartenente al probe set, all'interno del template set. Nel caso del dataset VIPeR utilizzato l'individuo i-esimo del probe set corrispondeva al i-esimo del template set.

In base al nome delle variabili contenenti il nuovo dataset fornito e le maschere sarà necessario sostituire con le nuove variabili le variabili msk e vecImage utilizzate nello script Program per il dataset VIPeR.