-- =================================================================
-- Фізична схема БД для Science-Connect Platform
-- =================================================================

-- --- Очищення старих таблиць ---
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS discussion_participants CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS shared_documents CASCADE;
DROP TABLE IF EXISTS scientific_ideas CASCADE;
DROP TABLE IF EXISTS online_orders CASCADE;
DROP TABLE IF EXISTS resources CASCADE;
DROP TABLE IF EXISTS online_discussions CASCADE;
DROP TABLE IF EXISTS users CASCADE;


-- --- Таблиця: users ---
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    user_name VARCHAR(255) NOT NULL CHECK (length(user_name) >= 2),
    email VARCHAR(255) NOT NULL UNIQUE,
    user_type VARCHAR(50) NOT NULL,
    field_of_study VARCHAR(255),
    department VARCHAR(255),

    -- Обмеження CHECK
    CHECK (user_type IN ('scientist', 'manager')),
    -- Регулярний вираз для email
    CHECK (email ~ '^\S+@\S+\.\S+$'),
    -- Перевірка, що для науковця вказана галузь, а для менеджера - відділ
    CHECK (
        (user_type = 'scientist' AND field_of_study IS NOT NULL)
        OR (user_type = 'manager' AND department IS NOT NULL)
    )
);

-- --- Таблиця: online_discussions ---
CREATE TABLE online_discussions (
    discussion_id SERIAL PRIMARY KEY,
    topic VARCHAR(500) NOT NULL CHECK (length(topic) >= 10),
    creation_date TIMESTAMPTZ NOT NULL DEFAULT current_timestamp
);

-- --- Таблиця: resources ---
CREATE TABLE resources (
    resource_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    resource_type VARCHAR(50) NOT NULL,
    model_number VARCHAR(100),
    author VARCHAR(255),
    publication_year INTEGER,

    -- Обмеження CHECK
    CHECK (resource_type IN ('equipment', 'literature')),
    -- Регулярний вираз для модельного номера
    CHECK (model_number IS NULL OR model_number ~ '^[A-Za-z0-9-]+$'),
    -- Перевірка року видання
    CHECK (
        publication_year IS NULL
        OR (
            publication_year >= 1500
            AND publication_year <= extract(YEAR FROM current_date)
        )
    ),
    -- Перевірка логіки
    CHECK (
        (resource_type = 'equipment' AND model_number IS NOT NULL)
        OR (resource_type = 'literature' AND author IS NOT NULL AND publication_year IS NOT NULL)
    )
);

-- --- Таблиця: online_orders ---

