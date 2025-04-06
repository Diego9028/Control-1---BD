CREATE DATABASE vuelos;

\c vuelos;

--- Tabla Cliente
CREATE TABLE Cliente (
    idCliente SERIAL PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL,
    edad INT CHECK (edad > 0),
    nacionalidad VARCHAR(20),
    correo VARCHAR(30) UNIQUE
);

--- Tabla Modelo
CREATE TABLE Modelo (
    idModelo SERIAL PRIMARY KEY,
    anioModelo INT NOT NULL,
    nombre VARCHAR(20) NOT NULL
);

--- Tabla Compañía
CREATE TABLE Compania (
    idCompania SERIAL PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL UNIQUE
);

--- Tabla Tipo de Empleado
CREATE TABLE TipoEmpleado (
    idTipoEmpleado SERIAL PRIMARY KEY,
    tipoEmpleo VARCHAR(20) NOT NULL UNIQUE
);

--- Tabla Sueldo
CREATE TABLE Sueldo (
    idSueldo SERIAL PRIMARY KEY,
    montoSueldo FLOAT CHECK (montoSueldo >= 0),
    fechaPago DATE NOT NULL
);

--- Tabla Sección (Tipo de clase de vuelo)
CREATE TABLE Seccion (
    idSeccion SERIAL PRIMARY KEY,
    tipoClase VARCHAR(20) NOT NULL
);

--- Tabla Avión
CREATE TABLE Avion (
    idAvion SERIAL PRIMARY KEY,
    idModelo INT NOT NULL,
    idCompania INT NOT NULL,
    adquisicion DATE NOT NULL,
    salidaCirculacion DATE,
    FOREIGN KEY (idModelo) REFERENCES Modelo(idModelo) ON DELETE CASCADE,
    FOREIGN KEY (idCompania) REFERENCES Compania(idCompania) ON DELETE CASCADE
);

--- Tabla Vuelo
CREATE TABLE Vuelo (
    idVuelo SERIAL PRIMARY KEY,
    idAvion INT NOT NULL,
    origen VARCHAR(20) NOT NULL,
    destino VARCHAR(20) NOT NULL,
    fechaDespegue DATE NOT NULL,
    FOREIGN KEY (idAvion) REFERENCES Avion(idAvion) ON DELETE CASCADE
);

--- Tabla Pasaje (Ahora ya existen Seccion y Vuelo)
CREATE TABLE Pasaje (
    idPasaje SERIAL PRIMARY KEY,
    idSeccion INT NOT NULL,
    idVuelo INT NOT NULL,
    costo FLOAT CHECK (costo >= 0),
    FOREIGN KEY (idSeccion) REFERENCES Seccion(idSeccion) ON DELETE CASCADE,
    FOREIGN KEY (idVuelo) REFERENCES Vuelo(idVuelo) ON DELETE CASCADE
);

--- Tabla Empleado (Ahora ya existen Compania, Sueldo y TipoEmpleado)
CREATE TABLE Empleado (
    idEmpleado SERIAL PRIMARY KEY,
    idCompania INT NOT NULL,
    idSueldo INT NOT NULL,
    idTipoEmpleado INT NOT NULL,
    nombre VARCHAR(60) NOT NULL,
    FOREIGN KEY (idCompania) REFERENCES Compania(idCompania) ON DELETE CASCADE,
    FOREIGN KEY (idSueldo) REFERENCES Sueldo(idSueldo) ON DELETE CASCADE,
    FOREIGN KEY (idTipoEmpleado) REFERENCES TipoEmpleado(idTipoEmpleado) ON DELETE CASCADE
);

--- Tabla Cliente_Comp (Ahora ya existen Cliente y Pasaje)
CREATE TABLE Cliente_Comp (
    idClienteComp SERIAL PRIMARY KEY,
    idPasaje INT NOT NULL,
    idCliente INT NOT NULL,
    FOREIGN KEY (idCliente) REFERENCES Cliente(idCliente) ON DELETE CASCADE,
    FOREIGN KEY (idPasaje) REFERENCES Pasaje(idPasaje) ON DELETE CASCADE
);

--- Tabla Vuelo_Empleado (Ahora ya existen Vuelo y Empleado)
CREATE TABLE Vuelo_Empleado (
    idVueloEmpleado SERIAL PRIMARY KEY,
    idVuelo INT NOT NULL,
    idEmpleado INT NOT NULL,
    FOREIGN KEY (idVuelo) REFERENCES Vuelo(idVuelo) ON DELETE CASCADE,
    FOREIGN KEY (idEmpleado) REFERENCES Empleado(idEmpleado) ON DELETE CASCADE
);