clear all
set more off

// Importación de datos
import excel "/Users/lucasordonez/Library/CloudStorage/OneDrive-Económicas-UBA/Econometria-Montes Rojas/Ayudante/20241C/DATA/CPI_USA_20224.xlsx", sheet("Hoja1") firstrow

// Generación de variable Fecha
gen Fecha = m(2000m1) + _n - 1
tsset Fecha, m
gen t = _n

// Generación de logaritmo del IPC
gen logIPC = ln(IPC)
gen dlogIPC = d.logIPC
label variable dlogIPC "Inflación mensual"

// Gráficos iniciales
tsline IPC, name(IPC)
tsline logIPC, name(logIPC)
graph combine IPC logIPC, col(1) iscale(1)
tsline dlogIPC

// Modelos ARIMA
arima dlogIPC, arima(1,0,0)
gen Ey_t = .0021555
label variable Ey_t "Esperanza"
tsline dlogIPC Ey_t

// Análisis de estacionariedad
dfuller logIPC
dfuller dlogIPC

// Selección de lags
varsoc dlogIPC if Fecha <= tm(2024m3), maxlag(12)

// Test de raíces unitarias
dfuller dlogIPC if Fecha <= tm(2024m3), lag(1)
dfuller dlogIPC if Fecha <= tm(2024m3), lag(1) trend reg

// Desestacionalización y extracción de tendencia (HP filter)
hprescott dlogIPC, stub(hplipc)
rename hplipc_dlogIPC_1 ciclo_hp
rename hplipc_dlogIPC_sm_1 tendencia_hp
tsline ciclo_hp tendencia_hp

// Ajuste polinómico
gen t2 = t^2
gen t3 = t^3
gen t4 = t^4

// Observación de tendencia y desestacionalización
preserve
reg dlogIPC t
predict Dlogipc_hat
reg dlogIPC t t2
predict Dlogipc_hat2
reg dlogIPC t t2 t3
predict Dlogipc_hat3
reg dlogIPC t t2 t3 t4
predict Dlogipc_hat4

tsline Dlogipc_hat tendencia_hp, name(tendencia1)
tsline Dlogipc_hat2 tendencia_hp, name(tendencia2)
tsline Dlogipc_hat3 tendencia_hp, name(tendencia3)
tsline Dlogipc_hat4 tendencia_hp, name(tendencia4)
graph combine tendencia1 tendencia2 tendencia3 tendencia4
tsline ciclo_hp tendencia_hp

restore



// Ajuste polinómico de grado 2 y residuos


reg dlogIPC t t2 
predict trend
predict CLEAN_INF, resid
label variable CLEAN_INF "Inflación sin tendencia"
tsline trend CLEAN_INF dlogIPC 

// Ajuste HP  y residuos
/*reg dlogIPC tendencia_hp
predict trend
predict CLEAN_INF, resid
label variable CLEAN_INF "Inflación sin tendencia"
tsline trend CLEAN_INF dlogIPC*/

// Chequeo de estacionalidad
generate group = floor((_n - 1) / 12)
generate mes = mod(_n - 1, 12) + 1

reg CLEAN_INF b(1)i.mes
predict estacio
predict CLEAN_INF2, resid
label variable CLEAN_INF2 "Inflación sin tendencia y estacionalidad"
tsline CLEAN_INF2 CLEAN_INF dlogIPC

// Serie estacionaria y análisis de autocorrelación
tsline CLEAN_INF2 dlogIPC
corrgram CLEAN_INF2
ac CLEAN_INF2, name(auto)
pac CLEAN_INF2, name(partauto)
graph combine auto partauto

// Modelos ARIMA y criterios de información

			// AIC		// BIC
//AR (1):	-2606.274  -2595.264
arima CLEAN_INF2, arima(1,0,0)
estat ic


//MA (1): -2617.16   *-2606.15*
arima CLEAN_INF2, arima(0,0,1)
estat ic


//ARMA (1,1): -2616.427  ***-2601.747***
arima CLEAN_INF2, arima(1,0,1)
estat ic

//AR (2):-2616.473  **-2601.794**
arima CLEAN_INF2, arima(2,0,0)
estat ic


// ARMA (2,1):-2615.305  -2596.955
arima CLEAN_INF2, arima(2,0,1)
estat ic


// Chequeo de correlación de residuos
arima CLEAN_INF2, arima(2,0,0)
predict er, resid
corrgram er
drop er

arima CLEAN_INF2, arima(1,0,1)
predict er2, resid
corrgram er2
drop er2

arima CLEAN_INF2, arima(0,0,1)
predict er3, resid
corrgram er3
drop er3



// Pronósticos ex-post

// 1) ARMA (1,1)
arima CLEAN_INF2 if Fecha < tm(2024m1), arima(1,0,1)
predict inf_pred1, dynamic(tm(2024m1))
gen inhat20 = inf_pred1 + trend + estacio
label variable inhat20 "Pronóstico ARMA (1,1)"
gen error_pron = dlogIPC - inhat20 if Fecha > tm(2023m12) & Fecha <= tm(2024m3)
gen error_pron_cuad = error_pron^2 if Fecha > tm(2023m12) & Fecha <= tm(2024m3)
rename error_pron ehat_arma11

//2024
tsline inhat20 dlogIPC if Fecha > tm(2023m12) & Fecha <= tm(2024m3)


//2023-2024
tsline inhat20 dlogIPC if Fecha > tm(2022m12) & Fecha <= tm(2024m3)


// 2) AR (2)
arima CLEAN_INF2 if Fecha < tm(2024m1), arima(2,0,0)
predict inf_pred2, dynamic(tm(2024m1))
gen inhat20_2 = inf_pred2 + trend + estacio
label variable inhat20_2 "Pronóstico AR (2)"
gen error_pron2 = dlogIPC - inhat20_2 if Fecha > tm(2023m12) & Fecha <= tm(2024m3)
gen error_pron_cuad2 = error_pron2^2 if Fecha > tm(2023m12) & Fecha <= tm(2024m3)
rename error_pron2 ehat_ar2

//2024
tsline inhat20_2 dlogIPC if Fecha > tm(2023m12) & Fecha <= tm(2024m3)


//2023-2024
tsline inhat20_2 dlogIPC if Fecha > tm(2022m12) & Fecha <= tm(2024m3)



// 3) MA(1)
arima CLEAN_INF2 if Fecha < tm(2024m1), arima(0,0,1)
predict inf_pred3, dynamic(tm(2024m1))
gen inhat20_3 = inf_pred3 + trend + estacio
label variable inhat20_3 "Pronóstico MA (1)"
gen error_pron3 = dlogIPC - inhat20_3 if Fecha > tm(2023m12) & Fecha <= tm(2024m3)
gen error_pron_cuad3 = error_pron3^2 if Fecha > tm(2023m12) & Fecha <= tm(2024m3)
rename error_pron3 ehat_ma1

//2024

tsline inhat20_3 dlogIPC if Fecha > tm(2023m12) & Fecha <= tm(2024m3)

//2023-2024

tsline inhat20_3 dlogIPC if Fecha > tm(2022m12) & Fecha <= tm(2024m3)





tsline inhat20 inhat20_2 inhat20_3 dlogIPC if Fecha > tm(2023m12) & Fecha <= tm(2024m3)

// Comparación de errores
sum ehat_arma11 ehat_ar2 ehat_ma1




// Pronósticos ex-ante

// ARMA (1,1)
* Estimar el modelo ARIMA solo para los datos hasta marzo de 2024
arima CLEAN_INF2 if Fecha < tm(2024m3), arima(1,0,1)

* Realizar la predicción dinámica desde abril de 2024 en adelante
predict inf_pred2_expost, dynamic(tm(2024m4))

* Generar la variable inhat21 con los componentes adicionales (tendencia y estacionalidad)
gen inhat21 = inf_pred2_expost + trend + estacio
label variable inhat21 "Pronóstico ARMA (1,1)"

* Calcular los intervalos de confianza al 95%
predict se, stdp
gen ub = inhat21 + 1.96*se
gen lb = inhat21 - 1.96*se

* Etiquetar los intervalos de confianza
label variable ub "Límite superior 95% IC"
label variable lb "Límite inferior 95% IC"

* Graficar la serie pronosticada junto con los intervalos de confianza y la serie observada
twoway (rarea lb ub Fecha if Fecha >= tm(2024m3) & Fecha <= tm(2024m12), color(gs12)) ///
       (tsline inhat21 if Fecha >= tm(2024m1) & Fecha <= tm(2024m12), lcolor(navy) lwidth(medium)) ///
       (tsline dlogIPC if Fecha >= tm(2024m1) & Fecha <= tm(2024m12), lcolor(red) lwidth(medium)), ///
       legend(label(1 "Intervalo de confianza 95%") label(2 "Pronóstico ARMA (1,1)") label(3 "dlogIPC observado")) ///
       title("Pronóstico ARMA (1,1) con Intervalo de Confianza 95%") ///
       xtitle("Fecha") ytitle("Valor")

	   
// MA(1)


* Estimar el modelo ARIMA solo para los datos hasta marzo de 2024
arima CLEAN_INF2 if Fecha < tm(2024m3  ), arima(0,0,1)

* Realizar la predicción dinámica desde abril de 2024 en adelante
predict inf_pred2_expost2, dynamic(tm(2024m4))

* Generar la variable inhat21 con los componentes adicionales (tendencia y estacionalidad)
gen inhat21_2 = inf_pred2_expost2 + trend + estacio
label variable inhat21_2 "Pronóstico MA (1)"

* Calcular los intervalos de confianza al 95%
predict se2, stdp
gen ub_2 = inhat21_2 + 1.96*se2
gen lb_2 = inhat21_2 - 1.96*se2

* Etiquetar los intervalos de confianza
label variable ub_2 "Límite superior 95% IC"
label variable lb_2 "Límite inferior 95% IC"

* Graficar la serie pronosticada junto con los intervalos de confianza y la serie observada
twoway (rarea lb_2 ub_2 Fecha if Fecha >= tm(2024m3) & Fecha <= tm(2024m12), color(gs12)) ///
       (tsline inhat21_2 if Fecha >= tm(2024m1) & Fecha <= tm(2024m12), lcolor(navy) lwidth(medium)) ///
       (tsline dlogIPC if Fecha >= tm(2024m1) & Fecha <= tm(2024m12), lcolor(red) lwidth(medium)), ///
       legend(label(1 "Intervalo de confianza 95%") label(2 "Pronóstico MA(1)") label(3 "dlogIPC observado")) ///
       title("Pronóstico MA (1) con Intervalo de Confianza 95%") ///
       xtitle("Fecha") ytitle("Valor")
	   
	   
	   
	   
// Comparación de pronósticos
tsline inhat21 inhat21_2 dlogIPC if Fecha > (tm(2023m12)) & Fecha <= (tm(2024m12))	   
	   
	   
	   
/*
// Pronósticos ex-ante

arima CLEAN_INF2 if Fecha < tm(2024m3), arima(1,0,1)
predict inf_pred2_expost, dynamic(tm(2024m4))
gen inhat21 = inf_pred2_expost + trend + estacio
label variable inhat21 "Pronóstico ARMA (1,1)"
tsline inhat21 dlogIPC if Fecha > (tm(2022m12)) & Fecha <= (tm(2024m12))

arima CLEAN_INF2 if Fecha < tm(2024m3), arima(0,0,1)
predict inf_pred2_expost2, dynamic(tm(2024m4))
gen inhat21_2 = inf_pred2_expost2 + trend + estacio
label variable inhat21_2 "Pronóstico MA (1)"
tsline inhat21_2 dlogIPC if Fecha > (tm(2023m12)) & Fecha <= (tm(2024m12))
*/
