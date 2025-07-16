# 📡 pgTcpCheck

`pgTcpCheck` es una función de PostgreSQL que permite realizar pruebas de conectividad TCP hacia uno o varios servidores especificados. Permite verificar si los destinos IP:PUERTO están accesibles desde el entorno actual, devolviendo una tabla con el estado de conexión individual por host.

---

## ¿Para qué sirve?

- Diagnosticar si un servidor está accesible por TCP (similar a `telnet` o `nc`)
- Validar que un servicio esté escuchando en el puerto indicado
- Usar dentro de procesos automatizados para controlar disponibilidad
- Ideal para entornos donde PostgreSQL necesita conectarse a otros nodos o servicios

---

## 🛠️ Requisitos

- PostgreSQL con PL/pgSQL habilitado
- El entorno del servidor debe permitir ejecutar comandos del sistema
- Acceso de red hacia los destinos IP/puerto

---

## 🧠 Notas adicionales

- Internamente utiliza shell para realizar la prueba:  
  `timeout X bash -c "echo > /dev/tcp/IP/PORT"`
- El tiempo de espera puede ajustarse si se parametriza el comando dentro de la función
- La salida puede integrarse fácilmente en procesos de auditoría, ETL o monitoreo

---

## Firma de la función

```sql
pgTcpCheckpgtcpheck(
           p_ip_servers TEXT,
           p_port INTEGER DEFAULT 5432,
           p_timeout INTEGER DEFAULT 2
          )								
RETURNS TABLE (
  ip_server INET,
  port INT,
  status_connect BOOLEAN
)
```

## 🔧 Ejemplos de uso

### ✅ Verificar una IP y puerto individual

```sql
SELECT * FROM pgTcpCheck('192.168.1.50', 5432);
```

📋 Resultado:

| ip_server     | port | status_connect |
|---------------|------|----------------|
| 192.168.1.50  | 5432 | f              |

---

### ✅ Verificar múltiples servidores en una sola llamada

```sql
SELECT * FROM pgTcpCheck('192.168.1.10:5418,192.168.1.20:5432,192.168.1.30:5416');
```

📋 Resultado:

| ip_server     | port | status_connect |
|---------------|------|----------------|
| 192.168.1.10  | 5418 | f              |
| 192.168.1.20  | 5432 | t              |
| 192.168.1.30  | 5416 | t              |



 
