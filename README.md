# condition_import
1. The script will retrieve CGD data file from http://research.nhgri.nih.gov/CGD/download/txt/CGD.txt.gz (default)
2. The script will save the retrieved file as CGD_<mm-dd-yyyy>.tsv.gz 
3. The script will unzip the file
4. The script will parse the CGD data file, and reorganize the information by conditions.
5. The script will recompress the file into bz2.

Useage:  Perl $0 

Prerequisite:
Perl,  POSTIX, curl, gunzip, bzip2
