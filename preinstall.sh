#!/bin/sh
cd ..
sudo ln -s pxp/lib lib
sudo ln -s pxp/index.php index.php
sudo ln -s pxp/sis_seguridad sis_seguridad
sudo ln -s pxp/sis_generador sis_generador
sudo ln -s pxp/sis_parametros sis_parametros
sudo ln -s pxp/sis_organigrama sis_organigrama
sudo ln -s pxp/sis_workflow sis_workflow
sudo mkdir reportes_generados
sudo mkdir uploaded_files
sudo touch sistemas.txt
#cd pxp/lib
#cp DatosGenerales.sample.php DatosGenerales.php
sudo setfacl -R -m u:apache:wrx uploaded_files
sudo setfacl -R -m u:apache:wrx reportes_generados
sudo chcon -Rv --type=httpd_sys_rw_content_t .
