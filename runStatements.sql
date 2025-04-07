--1) Lista de lugares al que más viajan los chilenos por año (durante los últimos 4 años).

SELECT anio, destino, cantidad_viajes
FROM (
    SELECT 
        EXTRACT(YEAR FROM v.fechaDespegue) AS anio,
        v.destino,
        COUNT(*) AS cantidad_viajes,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM v.fechaDespegue) ORDER BY COUNT(*) DESC) AS rnk
    FROM Cliente c
    JOIN Cliente_Comp cc ON c.idCliente = cc.idCliente
    JOIN Pasaje p ON cc.idPasaje = p.idPasaje
    JOIN Vuelo v ON p.idVuelo = v.idVuelo
    WHERE c.nacionalidad = 'Chileno'
      AND EXTRACT(YEAR FROM v.fechaDespegue) >= EXTRACT(YEAR FROM CURRENT_DATE) - 3
    GROUP BY anio, v.destino
) ranked
WHERE rnk = 1;

--2) Lista con las secciones de vuelos más compradas por argentinos.

SELECT 
    seccion.tipoclase, 
    COUNT(pasaje.idpasaje) AS total_pasajes
FROM cliente
INNER JOIN cliente_comp 
ON cliente.idcliente = cliente_comp.idcliente
INNER JOIN pasaje
ON cliente_comp.idpasaje = pasaje.idpasaje
INNER JOIN seccion
ON pasaje.idseccion = seccion.idseccion
WHERE cliente.nacionalidad = 'Argentino'
GROUP BY seccion.tipoclase
ORDER BY total_pasajes DESC;

--3) Lista mensual de países que más gastan en volar (durante los últimos 4 años).


SELECT DISTINCT ON (DATE_TRUNC('month', v.fechaDespegue))
    DATE_TRUNC('month', v.fechaDespegue) AS mes,
    c.nacionalidad AS pais,
    ROUND(SUM(p.costo)::numeric, 2) AS gasto_total
FROM Cliente c
JOIN Cliente_Comp cc ON c.idCliente = cc.idCliente
JOIN Pasaje p ON p.idPasaje = cc.idPasaje
JOIN Vuelo v ON v.idVuelo = p.idVuelo
WHERE v.fechaDespegue >= CURRENT_DATE - INTERVAL '4 years'
GROUP BY mes, pais
ORDER BY mes, gasto_total DESC;

--4) Lista de pasajeros que viajan en “First Class” más de 4 veces al mes.

SELECT 
    c.nombre AS pasajero,
    c.correo AS email,
    COUNT(p.idPasaje) AS viajes,
    DATE_TRUNC('month', v.fechaDespegue) AS mes
FROM 
    Cliente_Comp cc
JOIN 
    Cliente c ON cc.idCliente = c.idCliente
JOIN 
    Pasaje p ON cc.idPasaje = p.idPasaje
JOIN 
    Vuelo v ON p.idVuelo = v.idVuelo
WHERE 
    p.idSeccion = 4  -- "First Class"
GROUP BY 
    c.idCliente, c.nombre, c.correo, DATE_TRUNC('month', v.fechaDespegue)
HAVING 
    COUNT(p.idPasaje) > 4
ORDER BY 
    mes DESC, viajes DESC;


--5) Avión con menos vuelos.

SELECT 
    a.idAvion, 
    COUNT(v.idVuelo) AS total_vuelos
FROM 
    Avion a
LEFT JOIN 
    Vuelo v ON a.idAvion = v.idAvion
GROUP BY 
    a.idAvion
ORDER BY 
    total_vuelos ASC
LIMIT 1;

--6) Lista mensual de pilotos con mayor sueldo (durante los últimos 4 años).

SELECT 
    EXTRACT(YEAR FROM s.fechaPago) AS anio,
    e.nombre AS piloto,
    MAX(s.montoSueldo) AS sueldo
FROM 
    Empleado e
JOIN 
    Sueldo s ON e.idSueldo = s.idSueldo
JOIN 
    TipoEmpleado te ON e.idTipoEmpleado = te.idTipoEmpleado
WHERE 
    te.tipoEmpleo = 'Piloto'
    AND s.fechaPago >= DATE_TRUNC('year', NOW()) - INTERVAL '4 years'
GROUP BY 
    anio, e.nombre
ORDER BY 
    anio DESC, sueldo DESC;

--7) Lista de compañías indicando cuál es el avión que más ha recaudado en los últimos 4 años y cuál es el monto recaudado.

SELECT 
    comp.nombre AS compania,
    tr.idAvion,
    ROUND(tr.total_recaudado::numeric, 2) AS total_recaudado
FROM (
    SELECT 
        a.idCompania,
        a.idAvion,
        SUM(p.costo) AS total_recaudado,
        ROW_NUMBER() OVER (PARTITION BY a.idCompania ORDER BY SUM(p.costo) DESC) AS rn
    FROM Avion a
    JOIN Vuelo v ON v.idAvion = a.idAvion
    JOIN Pasaje p ON p.idVuelo = v.idVuelo
    WHERE v.fechaDespegue >= CURRENT_DATE - INTERVAL '4 years'
    GROUP BY a.idCompania, a.idAvion
) tr
JOIN Compania comp ON comp.idCompania = tr.idCompania
WHERE tr.rn = 1
ORDER BY comp.nombre;

--8) Lista de compañías y total de aviones por año (en los últimos 10 años).

WITH años AS (
    SELECT generate_series(
        EXTRACT(YEAR FROM CURRENT_DATE)::int - 9,  
        EXTRACT(YEAR FROM CURRENT_DATE)::int      
    ) AS anio
),
companias AS (
    SELECT idCompania, nombre FROM Compania
),
aviones_por_año AS (
    SELECT
        idCompania,
        EXTRACT(YEAR FROM adquisicion)::int AS anio_adquisicion,
        COUNT(*) AS total_aviones
    FROM Avion
    WHERE adquisicion <= CURRENT_DATE  
    GROUP BY idCompania, anio_adquisicion
)
SELECT 
    anios.anio,
    companias.nombre AS compania,
    COALESCE(SUM(CASE 
                    WHEN EXTRACT(YEAR FROM a.adquisicion) <= anios.anio AND 
                         (a.salidaCirculacion IS NULL OR EXTRACT(YEAR FROM a.salidaCirculacion) >= anios.anio) 
                    THEN 1 ELSE 0 
                END), 0) AS total_aviones
FROM años anios
CROSS JOIN companias  
LEFT JOIN Avion a 
    ON a.idCompania = companias.idCompania  
GROUP BY anios.anio, companias.nombre
ORDER BY anios.anio DESC, companias.nombre;

--9) Lista anual de compañías que en promedio han pagado más a sus empleados (durante los últimos 10 años).


SELECT DISTINCT ON (año)
    compania.nombre AS nombre_compania,
    EXTRACT(YEAR FROM sueldo.fechapago) AS año,
    AVG(sueldo.montosueldo) AS sueldopromedio
FROM empleado
JOIN compania ON empleado.idcompania = compania.idcompania
JOIN sueldo ON empleado.idsueldo = sueldo.idsueldo
WHERE sueldo.fechapago >= CURRENT_DATE - INTERVAL '10 years'
GROUP BY año, compania.idcompania, compania.nombre
ORDER BY año DESC, sueldopromedio DESC;

--10) Modelo de avión más usado por compañía durante el 2021.

SELECT DISTINCT ON (a.idCompania)
    a.idCompania,
    c.nombre AS nombre_compania,
    a.idModelo,
    m.nombre AS nombre_modelo,
    COUNT(v.idVuelo) AS total_vuelos
FROM Vuelo v
JOIN Avion a ON v.idAvion = a.idAvion
JOIN Modelo m ON a.idModelo = m.idModelo
JOIN Compania c ON a.idCompania = c.idCompania
WHERE EXTRACT(YEAR FROM v.fechaDespegue) = 2021
GROUP BY a.idCompania, c.nombre, a.idModelo, m.nombre
ORDER BY a.idCompania, COUNT(v.idVuelo) DESC;
