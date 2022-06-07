*** |  (C) 2006-2020 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/47_regipol/regiCarbonPrice/declarations.gms

***---------------------------------------------------------------------------
*** Auxiliar parameters:
***---------------------------------------------------------------------------

Parameter
  s47_firstFreeYear                                  "value of first free year for the carbon price trajectory"
  s47_prefreeYear                                    "value of the last non-free year for the carbon price trajectory"
  p47_LULUCFEmi_GrassiShift(ttot,all_regi)           "difference between Magpie land-use change emissions and UNFCCC emissions in 2015 to correct for national accounting in emissions targets"
  pm_emiMktTarget_dev(ttot,ttot2,ext_regi,emiMktExt) "deviation of emissions of current iteration from target emissions, for budget target this is the difference normalized by target emissions, while for year targets this is the difference normalized by 2005 emissions [%]"

*** RR this should be replaced as soon as non-energy is treated endoegenously in the model
  p47_nonEnergyUse(ttot,ext_regi)                  "non-energy use: EUR in 2030 =~ 90Mtoe (90 * 10^6 toe -> 90 * 10^6 toe * 41.868 GJ/toe -> 3768.12 * 10^6 GJ * 10^-9 EJ/GJ -> 3.76812 EJ * 1 TWa/31.536 EJ -> 0.1194863 TWa) EU27 =~ 92% EU28" / 2030.EUR_regi 0.1194863, 2030.EU27_regi 0.11 /
;

*** parameters to track regipol emissions calculation
Parameters
  p47_emiTargetMkt(ttot,all_regi,emiMktExt,emi_type_47)            "CO2 or GHG Emissions per emission market used for target level [GtC]"
  p47_emiTarget_grossEnCO2_noBunkers_iter(iteration,ttot,all_regi) "parameter to save value of gross energy emissions target over iterations to check whether values converge"
;

***--------------------------------------------------
*** Emission markets (EU Emission trading system and Effort Sharing)
***--------------------------------------------------
$ifThen.emiMkt not "%cm_emiMktTarget%" == "off" 
Parameter
  pm_emiMktTarget(ttot,ttot2,ext_regi,emiMktExt,target_type_47,emi_type_47) "region emissions target [GtCO2 or GtCO2eq]" / %cm_emiMktTarget% /

*** Initialization parameters (load data from the gdx)
  p47_taxemiMkt_init(ttot,all_regi,emiMkt)  "emiMkt CO2eq prices loaded from ref gdx, in T$/GtC = $/kgC. To get $/tCO2, multiply with 272 [T$/GtC]"
  p47_taxCO2eq_ref(ttot,all_regi)           "CO2eq prices loaded from ref gdx, in T$/GtC = $/kgC. To get $/tCO2, multiply with 272 [T$/GtC]"

*** Parameters necessary to calculate current emission target deviations
  pm_emiMktCurrent(ttot,ttot2,ext_regi,emiMktExt)    "previous iteration region emissions (from year ttot to ttot2 for budget) [GtCO2 or GtCO2eq]"
  p47_emiMktCurrent_iter(iteration,ttot,ttot2,ext_regi,emiMktExt) "parameter to save pm_emiMktCurrent across iterations  [GtCO2 or GtCO2eq]"
  pm_emiMktRefYear(ttot,ttot2,ext_regi,emiMktExt)    "emissions in reference year 2015, used for calculating target deviation of year targets [GtCO2 or GtCO2eq]"
  pm_emiMktTarget_dev_iter(iteration, ttot,ttot2,ext_regi,emiMktExt) "parameter to save pm_emiMktTarget_dev across iterations [%]"

*** Parameters necessary to calculate the emission tax rescaling factor
  p47_factorRescaleSlope(ttot,ttot2,ext_regi,emiMktExt)     "auxiliar parameter to save the slope corresponding to the observed mitigation derivative regarding to co2tax level changes from the two previous iterations [#]"
  p47_factorRescaleSlope_iter(iteration,ttot,ttot2,ext_regi,emiMktExt) "parameter to save mitigation curve slope [#]"
  p47_factorRescaleIntersect(ttot,ttot2,ext_regi,emiMktExt) "auxiliar parameter to save the intersect value of the linear projection of previous iterations mitigation levels when compared to relative price difference [#]" 
  p47_factorRescaleIntersect_iter(iteration,ttot,ttot2,ext_regi,emiMktExt) "parameter to save mitigation curve intersect [#]"
  pm_factorRescaleemiMktCO2Tax(ttot,ttot2,ext_regi,emiMktExt) "multiplicative tax rescale factor that rescales emiMkt carbon price from iteration to iteration to reach regipol targets [%]"
  p47_factorRescaleemiMktCO2Tax_iter(iteration,ttot,ttot2,ext_regi,emiMktExt) "parameter to save rescale factor across iterations for debugginh purposes [%]"

*** Parameters necessary to define the CO2 tax curve shape   
  p47_targetConverged(ttot,ext_regi)                 "boolean to store if emission target has converged [0 or 1]"
  p47_targetConverged_iter(iteration,ttot,ext_regi)  "parameter to save p47_targetConverged across iterations [0 or 1]"
  p47_allTargetsConverged(ext_regi)                  "boolean to store if all emission targets converged at least once [0 or 1]"
  p47_firstTargetYear(ext_regi)                      "first year with a pre defined policy emission target in the region [year]"
  p47_lastTargetYear(ext_regi)                       "last year with a pre defined policy emission target in the region [year]"
  p47_currentConvergencePeriod(ext_regi)             "auxiliar parameter to store the current target year being executed by the convergence algorithm [year]"
  p47_nextConvergencePeriod(ext_regi)                "auxiliar parameter to store the next target year being executed by the convergence algorithm [year]"
  p47_averagetaxemiMkt(ttot,all_regi)                "auxiliar parameter to store the weighted average convergence price between the current target terminal year and the next target year. Only applied for target years different than p47_lastTargetYear"
;

$ifThen.prioRescaleFactor not "%cm_prioRescaleFactor%" == "off" 
Parameter
  s47_prioRescaleFactor   "factor to prioritize short term targets in the initial iterations (and vice versa latter) [0..1]" / %cm_prioRescaleFactor% /
; 
$endIf.prioRescaleFactor
 
$endIf.emiMkt

***---------------------------------------------------------------------------
*** Implicit tax/subsidy necessary to achieve primary, secondary and/or final energy targets
***---------------------------------------------------------------------------

$ifthen.cm_implicitEnergyBound not "%cm_implicitEnergyBound%" == "off"
Parameter
  p47_implEnergyBoundTax(ttot,all_regi,energyCarrierLevel,energyType)          "tax/subsidy level on PE, SE and/or FE for an specific energy type"
  p47_implEnergyBoundCurrent(ttot,ext_regi,energyCarrierLevel,energyType)      "current iteration total PE, SE and/or FE for an specific energy type"
  p47_implEnergyBoundTax_Rescale(ttot,ext_regi,energyCarrierLevel,energyType)  "rescale factor for current implicit energy bound tax" 
  p47_implEnergyBoundTax_prevIter(ttot,all_regi,energyCarrierLevel,energyType) "previous iteration implicit energy bound target tax"
  p47_implEnergyBoundTax0(ttot,all_regi)                                       "previous iteration implicit energy bound target tax revenue"

  p47_implEnergyBoundTax_iter(iteration,ttot,all_regi,energyCarrierLevel,energyType)         "energy bound implicit tax per iteration"
  pm_implEnergyBoundTarget_dev(ttot,ext_regi,energyCarrierLevel,energyType)                 "energy bound implicit tax deviation of current iteration from target"
  p47_implEnergyBoundTarget_dev_iter(iteration,ttot,ext_regi,energyCarrierLevel,energyType)  "parameter to save pm_implEnergyBoundTarget_dev across iterations"
  p47_implEnergyBoundTax_Rescale_iter(iteration,ttot,ext_regi,energyCarrierLevel,energyType) "energy bound implicit tax rescale factor per iteration"    
  p47_implEnergyBoundCurrent_iter(iteration,ttot,ext_regi,energyCarrierLevel,energyType)     "total PE, SE and/or FE level for an specific energy type per iteration"   

  pm_implEnergyBoundTarget(ttot,ext_regi,taxType,targetType,energyCarrierLevel,energyType)  "Energy bound target [absolute: TWa; or percentage: 0.1]"  / %cm_implicitEnergyBound% /

  pm_implEnergyBoundLimited(iteration,energyCarrierLevel,energyType)  "1 (one) if there is a hard bound on the model that does not allow the tax to change further the energy usage"
;

Equations
  q47_implEnergyBoundTax(ttot,all_regi)  "implicit energy bound tax (PE, SE and/or FE for an specific energy type) to represent non CO2-price-driven policies"
;
$endIf.cm_implicitEnergyBound

***---------------------------------------------------------------------------
*'  Emission quantity target
***---------------------------------------------------------------------------

$ifThen.quantity_regiCO2target not "%cm_quantity_regiCO2target%" == "off"
Parameter
  p47_quantity_regiCO2target(ttot,ext_regi) "Exogenously emissions quantity constrain on net CO2 without bunkers [GtCO2]" / %cm_quantity_regiCO2target% /
;
equations
  q47_quantity_regiCO2target(ttot,ext_regi) "Exogenously emissions quantity constrain on net CO2 without bunkers [GtC]"
;
$endIf.quantity_regiCO2target   

***---------------------------------------------------------------------------
*** per region minimun variable renewables share in electricity:
***---------------------------------------------------------------------------
$ifthen.cm_VREminShare not "%cm_VREminShare%" == "off"

Variable
  v47_VREshare(ttot,all_regi) "share of variable renewables (wind and solar) in electricity"
;
Parameter
  p47_VREminShare(ttot,ext_regi) "per region minimun share of variable renewables (wind and solar) in electricity. Applied to yaers greater or equal to ttot. Unit [0..1]" / %cm_VREminShare% /  
;
Equation
  q47_VREShare(ttot,all_regi) "per region minimun share of variable renewables (wind and solar) from ttot year onward"
;

$endIf.cm_VREminShare

***---------------------------------------------------------------------------
*** Exogenous CO2 tax level:
***---------------------------------------------------------------------------

$ifThen.regiExoPrice not "%cm_regiExoPrice%" == "off"
Parameter
  p47_exoCo2tax(ext_regi,ttot)   "Exogenous CO2 tax level. Overrides carbon prices in pm_taxCO2eq, only if explicitly defined. Regions and region groups allowed. Format: '<regigroup>.<year> <value>, <regigroup>.<year2> <value2>' or '<regigroup>.(<year1> <value>,<year2> <value>'). [$/tCO2]" / %cm_regiExoPrice% /
;
$endIf.regiExoPrice


*** EOF ./modules/47_regipol/regiCarbonPrice/declarations.gms
