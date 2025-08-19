Mentalizing Signatures: Replication Code
===================================================

This repository contains the full analysis pipeline for the study:

    Açıl, D., ..., Koban, L., et al. (2025). "Brain neuromarkers predict self- and other-related mentalizing across adult, clinical, and developmental samples". Preprint available at bioRxiv: https://doi.org/10.1101/2025.03.10.642438


This code reproduces all analyses and figures reported in the manuscript. The pipeline includes:

- Training four cross-validated SVM classifiers of mentalizing processes
- Testing classifier predictions in six independent datasets
- Testing group differences (patient vs. healthy controls) in signature expressions as well as associations with age
- Training and validations ROI classifiers
- Generating figures and tables for both main text and supplementary material


Requirements
------------

- MATLAB R2022b or newer
- The following MATLAB toolboxes:
  - CanlabCore Toolbox (https://github.com/canlab/CanlabCore)
  - SPM12
  - Statistics and Machine Learning Toolbox
  - Signal Processing Toolbox
  - DataViz Toolbox (https://github.com/povilaskarvelis/DataViz)
- R (for generating figures of age associations)


License
-------

This code is released under the MIT License.
Please cite the original paper if you use this code in your own work.

Contact
-------

For questions, collaborations, or access to datasets, please contact:

- Dorukhan Açıl – dacil@cbs.mpg.de / doacil@pm.me
- Leonie Koban – leonie.koban@cnrs.fr

Citation
--------

@article{acil2025mentalizing,
  title={Brain neuromarkers predict self- and other-related mentalizing across adult, clinical, and developmental samples},
  author={Açıl, Dorukhan and Koban, Leonie and others},
  journal={bioRxiv},
  year={2025},
  doi={10.1101/2025.03.10.642438}
}# MS_GitHub

