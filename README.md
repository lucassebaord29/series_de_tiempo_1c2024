# Práctica I - Series de tiempo 

Utilizaremos el índice de Precios de USA (Consumer Price Index for All Urban Consumers), vale destacar que trabajaremos con la inflación mensual



Para estimar y hacer inferencia sobre la serie necesitamos que la serie de tiempo sea estacionaria. Ante un análisis grafico se puede observar con intuición acerca de la estacionariedad en sentido débil


Las condiciones estadísticas que buscamos es que $E[Y_t]$ y $VAR(y_t)$ sean constantes a lo largo del tiempo

Empezamos linkeando la base

```
clear all
set more off

// Importación de datos
import excel "/Users/lucasordonez/Library/CloudStorage/OneDrive-Económicas-UBA/Econometria-Montes Rojas/Ayudante/20241C/DATA/CPI_USA_20224.xlsx", sheet("Hoja1") firstrow

// Generación de variable Fecha
gen Fecha = m(2000m1) + _n - 1
tsset Fecha, m
gen t = _n
```

# Análisis de estacionariedad


Es recomendable trabajar con series logarítmicas, nos permite reducir la heterocedasticidad y suavizar la serie.


```
// Generación de logaritmo del IPC
gen logIPC = ln(IPC)
```
Graficando nuestra serie en niveles y la transformación logarítmica

```
// Gráficos iniciales
tsline IPC, name(IPC)
tsline logIPC, name(logIPC)
graph combine IPC logIPC, col(1) iscale(1)
```

<img width="1346" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/6e2ddf98-049c-4189-93fa-49a7e094a2a6">



Realizando la diferencia logarítmica del IPC aplicando el operador diferencia $\Delta y_t=y_t - y_{t-1}$. El comando es el siguiente en STATA:

```
d.logIPC
```

Al aplicar diferencias sobre la serie de IPC


$$ \Delta ln(IPC_t) = ln(IPC_t) - ln(IPC_{t-1})$$


Generamos una variable que representa la aproximación lineal de la **inflación mensual**. 

```
gen dlogIPC = d.logIPC
label variable dlogIPC "Inflación mensual"
```

Graficamos con el objetivo de intuir si existe tendencia (crece a lo largo de $t$) o tiene picos (comportamiento estacional)

```
tsline dlogIPC
```

<img width="1346" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/9e68694d-9930-4f9e-9be2-97f89979d11b">


## Análisis estadístico de la serie

### 1) Aplicamos filtro de Hodrick - Prescott, con el objetivo de conocer la descomposición de la serie, la tendencia y el ciclo


```

**TENDENCIA HP


hprescott dlogIPC, stub(hplipc)


*Genera las siguientes variables, por un lado ciclo y por otro tendencia

* hplipc_dlogIPC_1 // ciclo
* tsline hplipc_dlogIPC_sm_1  // tendencia

rename hplipc_dlogIPC_1 ciclo_hp
rename hplipc_dlogIPC_sm_1 tendencia_hp

* Grafico HP
tsline ciclo_hp tendencia_hp

```
Gráficamente:

<img width="1346" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/e4118a5b-8bcd-4d5e-be92-2edafbab7e26">

### 2) Aproximación de observación de tendencia y estacionalidad

Buscamos un polinomio de grado $n$, que se asemeje mas a nuestro modelo

```
* Primera aproximación de observación de tendencia y estacionalidad

*** Tendencia

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
*********************************************************************************
*observar la tendencia es simil a traves del filtro de hp y por otro lado con el ajuste polinomico



```
<img width="1458" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/bb882b07-354d-4dec-a1fb-8360d8e70779">

\
**Podemos conjeturar que un polinomio de grado 2 ajusta correctamente**

\
Nuestra salida en STATA es la siguiente:


<img width="1023" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/26d7c14f-1825-42a1-a93e-b1d92ef2631e">

\

Yo prefiero utilizar la tendencia de HP
\

<img width="1039" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/865406f3-82b2-4ea1-854b-ae34dc8da900">




Realizamos los valores predichos para obtener **tendencia** y por otro lado a través de los residuales de la regresión obtenemos la serie sin tendencia.

```
reg dlogIPC tendencia_hp
predict trend
predict CLEAN_INF, resid
label variable CLEAN_INF "Inflación sin tendencia"

```

Para el análisis de estacionalidad creamos $Q-1$ Dummy con los meses respectivos para descomponener el efecto mensual. El análisis se realiza sobre la serie sin tendencia. En primer lugar, creamos la variable mes y luego realizamos la regresión.

```
** Ahora tiramos una regresión de la serie limpia sin tendencia vs i.Mes para chequear estacionalidad
// Chequeo de estacionalidad
generate group = floor((_n - 1) / 12)
generate mes = mod(_n - 1, 12) + 1

reg CLEAN_INF b(1)i.mes
predict estacio
predict CLEAN_INF2, resid
label variable CLEAN_INF2 "Inflación sin tendencia y estacionalidad"
tsline CLEAN_INF2 CLEAN_INF dlogIPC  
```

<img width="1026" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/a8ee7f88-b761-4351-a1ee-f9ece68cebc1">



Se puede **observar estacionalidad en un par de meses**

```
reg CLEAN_INF b(1)i.Mes    // Se puede ver estacionalidad en un par de meses
predict estacio
predict CLEAN_INF2, resid
label variable CLEAN_INF2 "Inflación sin tendencia y estacionalidad"

```

\


<img width="1458" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/7ee82561-354f-49db-b549-bf3a3079e1ad">



\
Finalmente obtenemos nuestra serie estacionaria

```
tsline CLEAN_INF2 dlogIPC
```


<img width="1458" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/18cee1f9-e6df-47e7-a77d-36be6b689d2e">


## 3) Contraste de Dickey Fuller
Anteriormente observamos que la serie con la que estamos trabajando presenta un **componente tendencial** por ende la serie **no puede ser estacionaria**

Aplicamos este test con el objetivo de buscar **Raices unitarias**


### 1° Test simple de Dickey-Fuller
Analizamos si la serie presenta estacionariedad a través del test de Dickey - Fuller, el objetivo de este test es testear si se presenta raíz unitaria 

Ejemplo AR(1):

$$ Y_T = \rho Y_{T-1} + e_t$$


$$\Delta  Y_T = \theta Y_{T-1} + e_t$$

Donde $\theta = \rho - 1$

Si $H_0: \theta = 0 \Rightarrow$ se presenta raíz unitaria

Si $H_0: \theta = 0 <0 \Rightarrow$ no se presenta raíz unitaria


```
dfuller logIPC

```
\
Nuestra salida en STATA es la siguiente:

<img width="1041" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/dcd68f6f-3410-424d-a037-c7b39d6f9325">


\
Se presenta Raíz unitaria, ya que no rechazamos la hipótesis nula. Aplicando el operador diferencia nos permite trabajar con un orden de integracion 0 I(0)

```
dfuller dlogIPC
```

\
Nuestra salida en STATA es la siguiente:


<img width="1036" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/47110653-ccee-4046-b41a-19c154bdd556">


\
Rechazamos $H_0$, no se presenta raíz unitaria



### 2° Test de Dickey-Fuller ampliado

Con este comando vemos la cantidad de rezagos óptimos en nuestro modelo, optamos por un rezago por criterio Bayesiano

```
// Selección de lags
varsoc dlogIPC if Fecha <= tm(2024m3), maxlag(12)
```


\
Nuestra salida en STATA es la siguiente:



<img width="1039" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/67a92ec6-10ef-4349-8f75-761f32b81ed0">



\
Luego testeo a traves de estos rezagos en el test:


```
/* 2) Testeo */

dfuller dlogIPC if Fecha <= tm(2024m3), lag(1)

```

\
Nuestra salida en STATA es la siguiente:



<img width="1021" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/83fd584a-fb27-48d5-90b4-194a71d23d2e">



\
También a través del Test puedo observar la significancia de la tendencia  




```
*Si quiero identificar si la serie tiene una tendencia deterministica (si por el mero paso del tiempo se modifica la Y_t)

dfuller dlogIPC if Fecha <= tm(2024m3), lag(1) trend reg
```


Nuestra salida en STATA:

<img width="1037" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/ee5ab90c-5b77-47bf-82dc-c2775a1a41d7">




\
En este caso no es significativo


# Correlograma de la serie

---------
**arma**

La serie de tiempo depende de una **constante + algunos rezagos donde aparece el rezago de la variable independiente + otros rezagos a traves de los shocks**


Para los MA -> función de autocorrelación. 

comando

```
ac variable

```
Calcula los coeficientes que se corresponden con la autocorrelación, los que estan por fuera del intervalo de confianza son estadisticamente significativos

**OBSERVACIÓN: LA AUTOCORRELACIÓN SIRVE PARA ELEGIR LA CANTIDAD DE REZAGOS DE LOS PROMEDIOS MOVILES**
```
corrgram variable
```
calcula todas las autocorrelaciones y las expone en una tabla

**FUNCION DE AUTOCORRELACIÓN**: nos dice las correlaciones que hay entre cada periodo y sus rezagos, entonces nos va a servir para ver si hay estacionalidad

La funcion de autocorrelación no nos sirve para elegir la cantidad de rezagos de la parte AR, en general, lo que se ve es que la autocorrelación va cayendo lentamente. 

**FUNCION DE AUTOCORRELACIÓN PARCIAL** -> orden AR.
Para estimar el valor de la autocorrelación parcial de orden 2 estoy controlando de forma parcial por el efecto de lo que paso en $t-1$.

comando

```
pac variable
```

--------
Una aclaración importante es que debemos trabajar sobre nuestra serie estacionaria (Sin tendencia ni estacionalidad)

Realizando un **analisis subjetivo** en base a los **gráficos** de la **función de autorcorrelación (AC)** y la **funcion de autocorrelación parcial (PAC)**, nos acercamos a la cantidad de rezagos de la parte MA y la parte AR del modelo.


Una primera aproximación es utilizar el siguiente comando:


```
corrgram CLEAN_INF2

```

La salida en STATA es la siguiente:

<img width="879" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/5055a0e1-6f95-4b78-90dc-fb408cd5845d">


\
Podemos inferir de forma mas precisa graficando la **función de autorcorrelación (AC)** y la **funcion de autocorrelación parcial (PAC)** con los siguientes comandos:

```
ac CLEAN_INF2, name(auto)
pac CLEAN_INF2, name(partauto)
graph combine auto partauto 
```


Los gráficos son los siguientes:


<img width="1458" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/15edae79-1c75-4f4c-b570-c974d4b35f22">


¿Qué pueden inferir graficamente?


Para realizar una análisis mas robusto utilizamos **los critorios de información**, probamos distintos modelos ARMA. A la hora de elegir nos quedamos con el modelo que reporte el **minimo** valor

### **ARIMA (1,0,0)**

<img width="866" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/a70bd44e-0247-4796-8230-f1040165ce33">



### **ARIMA (0,0,1)**

<img width="871" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/0ad3a8dd-3bd9-46d7-b5e1-2e7d77431eb7">


### **ARIMA (1,0,1)**


<img width="866" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/15f4dda4-767b-4a3e-9f5d-23f909e0ab82">


### **ARIMA (2,0,0)**


<img width="864" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/d9a40c36-a12b-441e-b4d0-a50a672af0e4">






### MA(1)
```
-----------------------------------------------------------------------------
       Model |        Obs  ll(null)  ll(model)      df         AIC        BIC
-------------+---------------------------------------------------------------
           . |        290         .    1311.58       3    -2617.16   -2606.15
-----------------------------------------------------------------------------

```

### ARMA(1,1)

```
-----------------------------------------------------------------------------
       Model |        Obs  ll(null)  ll(model)      df         AIC        BIC
-------------+---------------------------------------------------------------
           . |        290         .   1312.214       4   -2616.427  -2601.747
-----------------------------------------------------------------------------


```
### AR(2)

```
-----------------------------------------------------------------------------
       Model |        Obs  ll(null)  ll(model)      df         AIC        BIC
-------------+---------------------------------------------------------------
           . |        290         .   1312.237       4   -2616.473  -2601.794
-----------------------------------------------------------------------------

```

En base a los criterios de información el ARMA(1,1) y AR(1) son los mejores modelos a utilizar. A fines prácticos trabajaremos con los 3 modelos seleccionados para ver diferencias y similitudes.


Como siguiente paso verificamos si existe correlación con los ruidos blancos de nuestros modelos. Corremos en STATA el correlograma de los errores de predicción del modelo AR (2) para los datos de nuestra base de inflación para tener más información sobre la elección del modelo además de los criterios de información


```
arima CLEAN_INF2, arima (2,0,0)
predict er, resid
corrgram er
drop er

```

La salida de STATA es la siguiente:

<img width="883" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/5efd91c8-840b-4e05-b957-7d30fc1c1760">


\
Corremos en STATA el correlograma de los errores de predicción del modelo ARMA (1,1) para los datos de nuestra base de inflación para tener más información sobre la elección del modelo además de los criterios de información

```
arima CLEAN_INF2, arima (1,0,1)
predict er2, resid
corrgram er2
drop er2
```

La salida de STATA es la siguiente:

<img width="879" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/34be31d6-de10-4bc2-81a6-d27c405d89d4">


Corremos en STATA el correlograma de los errores de predicción del modelo MA (1) para los datos de nuestra base de inflación para tener más información sobre la elección del modelo además de los criterios de información.


```
arima CLEAN_INF2, arima (0,0,1)
predict er3, resid
corrgram er3
drop er3
```

La salida de STATA es la siguiente:


<img width="877" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/75e2c843-8288-4634-a076-1d861e7dbeed">


# Predicción

Presentando los datos de la inflación de 2024 hasta el mes de marzo, evaluaremos qué tan bien predice nuestro modelo constrastando la inflación realizada. Existen 3 instancias para entrenar nuestro modelo:


1) In sample forecast o parte training: entrenamos al modelo dentro de la muestra con valores conocidos (estimación de regresión arima)

2) Ex post out of sample forecast o parte testing: pronóstico mas allá de la muestra de la regresión testeando contra valores conocidos (ya realizados ex-post)

3) Ex ante out of sample forecast: pronóstico mas allá de la muestra de la regresión y de los valores conocidos (estimo el futuro)


### Modelo ARMA(1,1)

1) In sample forecast o parte training

```
arima CLEAN_INF2 if Fecha < tm(2024m1), arima(1,0,1)
```

2) Ex post out of sample forecast o parte testing:


```
predict inf_pred1, dynamic(tm(2024m1))
gen inhat20 = inf_pred1 + trend + estacio


```

**Debemos sumar la tendencia y la estacionalidad**

Graficamos

```
//2024
tsline inhat20 dlogIPC if Fecha > tm(2023m12) & Fecha <= tm(2024m3)


//2023-2024
tsline inhat20 dlogIPC if Fecha > tm(2022m12) & Fecha <= tm(2024m3)
```

El primer gráfico muestra nuestra predicción a lo largo del año 2024

<img width="1458" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/9c2fe1d2-3c79-420e-b6aa-3aa1edf66a38">



El segundo gráfico muestra nuestro modelo junto con la predicción del año 2024 para el período 2023-2024

<img width="1458" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/8714f291-f062-4aeb-89f6-a9df2d49c29a">





### Modelo AR (2)

Siguiendo los mismos pasos que utilizamos en el modelo anterior obtenemos los siguientes resultados:


Graficamos

```
//2024
tsline inhat20_2 dlogIPC if Fecha > tm(2023m12) & Fecha <= tm(2024m3)


//2023-2024
tsline inhat20_2 dlogIPC if Fecha > tm(2022m12) & Fecha <= tm(2024m3)
```

El primer gráfico muestra nuestra predicción a lo largo del año 2024

<img width="1458" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/9de58aa7-bd7a-4f57-9f8c-d0bbda670df6">



El segundo gráfico muestra nuestro modelo junto con la predicción del año 2024 para el período 2023-2024

<img width="1458" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/74ffcd48-dbcb-47f7-bcf5-b69e98d8b102">



### Modelo MA(1)

Siguiendo los mismos pasos que utilizamos en el modelo anterior obtenemos los siguientes resultados:


Graficamos

```
//2024

tsline inhat20_3 dlogIPC if Fecha > tm(2023m12) & Fecha <= tm(2024m3)

//2023-2024

tsline inhat20_3 dlogIPC if Fecha > tm(2022m12) & Fecha <= tm(2024m3)
```

El primer gráfico muestra nuestra predicción a lo largo del año 2024

<img width="1458" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/add54e6d-9193-4b2d-8d02-c4ce1f670261">



El segundo gráfico muestra nuestro modelo junto con la predicción del año 2024 para el período 2023-2024

<img width="1458" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/5dcc4956-fa17-4ed2-aaca-43ab55842f39">



### Comparación de pronósticos

<img width="1458" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/6f934669-6824-488f-9d72-ddb22dac3c66">



Una aplicación util es comparar los errores de nuestro modelo:

```
gen error_pron = dlogIPC - inhat20 if Fecha > tm(2023m12) & Fecha <= tm(2024m3)
gen error_pron_cuad = error_pron^2 if Fecha > tm(2023m12) & Fecha <= tm(2024m3)
rename error_pron ehat_arma11


gen error_pron2 = dlogIPC - inhat20_2 if Fecha > tm(2023m12) & Fecha <= tm(2024m3)
gen error_pron_cuad2 = error_pron2^2 if Fecha > tm(2023m12) & Fecha <= tm(2024m3)
rename error_pron2 ehat_ar2


gen error_pron3 = dlogIPC - inhat20_3 if Fecha > tm(2023m12) & Fecha <= tm(2024m3)
gen error_pron_cuad3 = error_pron3^2 if Fecha > tm(2023m12) & Fecha <= tm(2024m3)
rename error_pron3 ehat_ma1

// Comparación de errores
sum ehat_arma11 ehat_ar2 ehat_ma1

```

<img width="867" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/0b888bd1-1f21-4941-9d72-8883d179772f">



### Pronóstico Ex ante out of sample forecast

### ARMA (1,1)

```
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

```

<img width="1313" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/2f45a34f-f8c0-4c1d-9c96-e64cbe7022ee">


### MA (1)

```
// MA(1)


* Estimar el modelo ARIMA solo para los datos hasta marzo de 2024
arima CLEAN_INF2 if Fecha < tm(2024m3), arima(0,0,1)

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

```

<img width="1313" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/8ccf0a8a-28e8-4e45-91aa-8ee5eaac83fd">



### Comparación: ARMA (1,1) vs MA (1)

<img width="1313" alt="image" src="https://github.com/lucassebaord29/series_de_tiempo_1c2024/assets/67765423/f884e6c2-5078-4571-bc6f-bbc9b3bd6917">


