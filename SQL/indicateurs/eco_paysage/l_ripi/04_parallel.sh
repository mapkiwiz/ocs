#!/bin/bash

function compute_lin_dgo {

	DEPT=$1
	psql <<< "SELECT ripi.lin_ripisylve('$DEPT');" 2>&1 > /tmp/$DEPT.log

}

compute_lin_dgo AIN
compute_lin_dgo ALLIER
compute_lin_dgo CANTAL

compute_lin_dgo ARDECHE
compute_lin_dgo DROME
compute_lin_dgo HAUTE-LOIRE

compute_lin_dgo HAUTE-SAVOIE
compute_lin_dgo ISERE
compute_lin_dgo LOIRE

compute_lin_dgo PUY-DE-DOME
compute_lin_dgo RHONE
compute_lin_dgo SAVOIE
