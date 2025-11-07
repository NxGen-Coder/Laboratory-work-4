import os  # F401: 'os' imported but unused

def main():
    """
    Головна функція, що виводить назву програмного продукту.
    Цей файл містить помилку для лінтера.
    """
    product_name = "Science-Connect Platform"
    print(f"Назва програмного продукту: {product_name}")


if __name__ == "__main__":
    main()
