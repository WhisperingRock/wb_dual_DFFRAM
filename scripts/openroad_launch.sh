export PDKPATH=/home/whirck/.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130A/

printf "\
read_db `find runs/recent/final/odb/*`
read_liberty  $PDKPATH/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib
read_sdc  `find runs/recent/final/sdc/*`
gui::show \n"
