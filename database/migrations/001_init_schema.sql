-- =========================================================
-- Panel Operativo - Maquinaria e Insumos Petroleros
-- Migración inicial: creación de esquema completo
-- =========================================================

-- Extensión necesaria para generar UUIDs
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------
-- NÚCLEO COMPARTIDO
-- ---------------------------------------------------------

create table clientes (
    id uuid primary key default gen_random_uuid(),
    nombre text not null,
    nit text,
    tipo_cliente text check (tipo_cliente in ('empresa', 'persona_natural')),
    contacto text,
    created_at timestamptz not null default now()
);

create table proveedores (
    id uuid primary key default gen_random_uuid(),
    nombre text not null,
    contacto text,
    created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- RAMA: MAQUINARIA
-- ---------------------------------------------------------

create table categorias_maquinaria (
    id uuid primary key default gen_random_uuid(),
    nombre text not null unique
);

create table maquinas (
    id uuid primary key default gen_random_uuid(),
    categoria_id uuid not null references categorias_maquinaria(id),
    codigo_activo text not null unique,
    marca text,
    modelo text,
    numero_serie text,
    estado_actual text not null default 'disponible'
        check (estado_actual in ('disponible', 'alquilada', 'mantenimiento', 'fuera_servicio')),
    tarifa_diaria numeric(12,2),
    created_at timestamptz not null default now()
);

create table contratos_alquiler (
    id uuid primary key default gen_random_uuid(),
    cliente_id uuid not null references clientes(id),
    maquina_id uuid not null references maquinas(id),
    fecha_inicio date not null,
    fecha_fin date,
    tarifa numeric(12,2) not null,
    estado_contrato text not null default 'activo'
        check (estado_contrato in ('activo', 'finalizado', 'cancelado')),
    created_at timestamptz not null default now()
);

create table historial_estados (
    id uuid primary key default gen_random_uuid(),
    maquina_id uuid not null references maquinas(id),
    estado text not null,
    ubicacion text,
    fecha_cambio timestamptz not null default now()
);

create table mantenimientos (
    id uuid primary key default gen_random_uuid(),
    maquina_id uuid not null references maquinas(id),
    tipo text not null,
    fecha date not null,
    costo numeric(12,2),
    proximo_mantenimiento date,
    created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- RAMA: INSUMOS PETROLEROS
-- ---------------------------------------------------------

create table categorias_producto (
    id uuid primary key default gen_random_uuid(),
    nombre text not null unique
);

create table productos (
    id uuid primary key default gen_random_uuid(),
    categoria_id uuid not null references categorias_producto(id),
    nombre text not null,
    unidad_medida text not null,
    stock_actual numeric(12,2) not null default 0,
    stock_minimo numeric(12,2) not null default 0,
    created_at timestamptz not null default now()
);

create table movimientos_inventario (
    id uuid primary key default gen_random_uuid(),
    producto_id uuid not null references productos(id),
    proveedor_id uuid references proveedores(id),
    tipo_movimiento text not null check (tipo_movimiento in ('entrada', 'salida')),
    cantidad numeric(12,2) not null,
    motivo text,
    fecha timestamptz not null default now()
);

create table ventas_insumos (
    id uuid primary key default gen_random_uuid(),
    cliente_id uuid not null references clientes(id),
    fecha date not null default current_date,
    total numeric(12,2) not null default 0
);

create table detalle_venta (
    id uuid primary key default gen_random_uuid(),
    venta_id uuid not null references ventas_insumos(id) on delete cascade,
    producto_id uuid not null references productos(id),
    cantidad numeric(12,2) not null,
    precio_unitario numeric(12,2) not null
);

-- ---------------------------------------------------------
-- ÍNDICES para consultas frecuentes del panel
-- ---------------------------------------------------------

create index idx_maquinas_estado on maquinas(estado_actual);
create index idx_historial_maquina on historial_estados(maquina_id, fecha_cambio);
create index idx_contratos_estado on contratos_alquiler(estado_contrato);
create index idx_movimientos_producto on movimientos_inventario(producto_id, fecha);
create index idx_productos_stock_bajo on productos(stock_minimo);
