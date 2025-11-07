-- =================================================================
-- Фізична схема БД для Science-Connect Platform
-- =================================================================

-- --- Очищення старих таблиць (для повторного запуску) ---
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
    user_name VARCHAR(255) NOT NULL CHECK (LENGTH(user_name) >= 2),
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
    topic VARCHAR(500) NOT NULL CHECK (LENGTH(topic) >= 10),
    creation_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
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
    -- Перевірка року видання (ВИПРАВЛЕНО РЕГІСТР ФУНКЦІЙ)
    CHECK (
        publication_year IS NULL
        OR (
            publication_year >= 1500
            AND publication_year <= EXTRACT(YEAR FROM CURRENT_DATE)
        )
    ),
    -- Перевірка логіки (ВИПРАВЛЕНО ФОРМАТУВАННЯ)
    CHECK (
        (resource_type = 'equipment' AND model_number IS NOT NULL)
        OR (
            resource_type = 'literature'
            AND author IS NOT NULL
            AND publication_year IS NOT NULL
        )
    )
);

-- --- Таблиця: online_orders ---
CREATE TABLE online_orders (
    order_id SERIAL PRIMARY KEY,
    scientist_id INTEGER NOT NULL,
    manager_id INTEGER,
    order_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Виправлено: 'status' -> 'order_status'
    order_status VARCHAR(50) NOT NULL DEFAULT 'new',

    -- Обмеження FOREIGN KEY (ВИПРАВЛЕНО ФОРМАТУВАННЯ)
    FOREIGN KEY (scientist_id) REFERENCES users (user_id) ON DELETE RESTRICT,
    FOREIGN KEY (manager_id) REFERENCES users (user_id) ON DELETE SET NULL,

    -- Обмеження CHECK
    CHECK (order_status IN ('new', 'processing', 'confirmed', 'rejected'))
);

-- --- Таблиця: scientific_ideas ---
CREATE TABLE scientific_ideas (
    idea_id SERIAL PRIMARY KEY,
    author_id INTEGER NOT NULL,
    discussion_id INTEGER NOT NULL,
    description TEXT NOT NULL CHECK (LENGTH(description) >= 50),
    submission_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Обмеження FOREIGN KEY (ВИПРАВЛЕНО ФОРМАТУВАННЯ)
    FOREIGN KEY (author_id) REFERENCES users (user_id) ON DELETE RESTRICT,
    FOREIGN KEY (discussion_id)
    REFERENCES online_discussions (discussion_id) ON DELETE CASCADE
);

-- --- Таблиця: shared_documents ---
CREATE TABLE shared_documents (
    document_id SERIAL PRIMARY KEY,
    discussion_id INTEGER NOT NULL,
    file_path VARCHAR(1024) NOT NULL,
    document_type VARCHAR(50),

    -- Обмеження FOREIGN KEY (ВИПРАВЛЕНО ФОРМАТУВАННЯ)
    FOREIGN KEY (discussion_id)
    REFERENCES online_discussions (discussion_id) ON DELETE CASCADE,
    CHECK (document_type IN ('PDF', 'DOCX', 'URL', 'Other'))
);

-- --- Таблиця: comments ---
CREATE TABLE comments (
    comment_id SERIAL PRIMARY KEY,
    author_id INTEGER NOT NULL,
    discussion_id INTEGER,
    idea_id INTEGER,
    comment_text TEXT NOT NULL CHECK (LENGTH(comment_text) >= 1),
    creation_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Обмеження FOREIGN KEY (ВИПРАВЛЕНО ФОРМАТУВАННЯ)
    FOREIGN KEY (author_id) REFERENCES users (user_id) ON DELETE RESTRICT,
    FOREIGN KEY (discussion_id)
    REFERENCES online_discussions (discussion_id) ON DELETE CASCADE,
    FOREIGN KEY (idea_id) REFERENCES scientific_ideas (
        idea_id
    ) ON DELETE CASCADE,
    CHECK (
        (discussion_id IS NOT NULL AND idea_id IS NULL)
        OR (discussion_id IS NULL AND idea_id IS NOT NULL)
    )
);

-- --- Сполучна таблиця: discussion_participants ---
CREATE TABLE discussion_participants (
    user_id INTEGER NOT NULL,
    discussion_id INTEGER NOT NULL,
    PRIMARY KEY (user_id, discussion_id),

    -- Обмеження FOREIGN KEY (ВИПРАВЛЕНО ФОРМАТУВАННЯ)
    FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
    FOREIGN KEY (discussion_id)
    REFERENCES online_discussions (discussion_id) ON DELETE CASCADE
);

-- --- Сполучна таблиця: order_items ---
CREATE TABLE order_items (
    order_id INTEGER NOT NULL,
    resource_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (order_id, resource_id),

    -- Обмеження FOREIGN KEY (ВИПРАВЛЕНО ФОРМАТУВАННЯ)
    FOREIGN KEY (order_id) REFERENCES online_orders (
        order_id
    ) ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES resources (
        resource_id
    ) ON DELETE RESTRICT,
    CHECK (quantity > 0)
);

-- --- Індекси для прискорення запитів ---
CREATE INDEX ON scientific_ideas (author_id);
CREATE INDEX ON scientific_ideas (discussion_id);
CREATE INDEX ON comments (author_id);
CREATE INDEX ON comments (discussion_id);
CREATE INDEX ON comments (idea_id);
CREATE INDEX ON online_orders (scientist_id);
CREATE INDEX ON online_orders (manager_id);
