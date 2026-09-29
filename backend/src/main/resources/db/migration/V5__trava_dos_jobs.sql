-- Trava distribuída dos jobs agendados (ShedLock, 0.4.0 item 6): com várias instâncias do backend, cada job roda
-- em uma instância por vez.

CREATE TABLE shedlock (
    name varchar(64) NOT NULL PRIMARY KEY,
    lock_until timestamp NOT NULL,
    locked_at timestamp NOT NULL,
    locked_by varchar(255) NOT NULL
);
