-- Custo estimado do veículo (0.5.0, item 3): o entregador informa, se quiser, o consumo e o preço do combustível,
-- e a manutenção e a depreciação por km. A aba Ganhos usa esses valores para mostrar o resultado estimado.

ALTER TABLE vehicles
    ADD COLUMN fuel_consumption_km_per_liter numeric(6,2) CHECK (fuel_consumption_km_per_liter > 0),
    ADD COLUMN fuel_price_per_liter numeric(6,2) CHECK (fuel_price_per_liter >= 0),
    ADD COLUMN maintenance_per_km numeric(6,3) CHECK (maintenance_per_km >= 0),
    ADD COLUMN depreciation_per_km numeric(6,3) CHECK (depreciation_per_km >= 0);
